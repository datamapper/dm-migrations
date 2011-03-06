require 'dm-migrations/auto_migration'
require 'dm-migrations/adapters/dm-do-adapter'

module DataMapper
  module Migrations
    module OracleAdapter

      include DataObjectsAdapter

      # @api private
      def self.included(base)
        base.extend DataObjectsAdapter::ClassMethods
        base.extend ClassMethods
      end

      # @api semipublic
      def storage_exists?(storage_name)
        statement = DataMapper::Ext::String.compress_lines(<<-SQL)
          SELECT COUNT(*)
          FROM all_tables
          WHERE owner = ?
          AND table_name = ?
        SQL

        select(statement, schema_name, oracle_upcase(storage_name)).first > 0
      end

      # @api semipublic
      def sequence_exists?(sequence_name)
        return false unless sequence_name
        statement = DataMapper::Ext::String.compress_lines(<<-SQL)
          SELECT COUNT(*)
          FROM all_sequences
          WHERE sequence_owner = ?
          AND sequence_name = ?
        SQL

        select(statement, schema_name, oracle_upcase(sequence_name)).first > 0
      end

      # @api semipublic
      def field_exists?(storage_name, field_name)
        statement = DataMapper::Ext::String.compress_lines(<<-SQL)
          SELECT COUNT(*)
          FROM all_tab_columns
          WHERE owner = ?
          AND table_name = ?
          AND column_name = ?
        SQL

        select(statement, schema_name, oracle_upcase(storage_name), oracle_upcase(field_name)).first > 0
      end

      # @api semipublic
      def storage_fields(storage_name)
        statement = DataMapper::Ext::String.compress_lines(<<-SQL)
          SELECT column_name
          FROM all_tab_columns
          WHERE owner = ?
          AND table_name = ?
        SQL

        select(statement, schema_name, oracle_upcase(storage_name))
      end

      def drop_table_statement(model)
        table_name = quote_name(model.storage_name(name))
        "DROP TABLE #{table_name} CASCADE CONSTRAINTS"
      end


      # @api semipublic
      def create_model_storage(model)
        name       = self.name
        properties = model.properties_with_subclasses(name)
        table_name = model.storage_name(name)
        truncate_or_delete = self.class.auto_migrate_with
        table_is_truncated = truncate_or_delete && @truncated_tables && @truncated_tables[table_name]

        return false if storage_exists?(table_name) && !table_is_truncated
        return false if properties.empty?

        with_connection do |connection|
          # if table was truncated then check if all columns for properties are present
          # TODO: check all other column definition options
          if table_is_truncated && storage_has_all_fields?(table_name, properties)
            @truncated_tables[table_name] = nil
          else
            # forced drop of table if properties are different
            if truncate_or_delete
              destroy_model_storage(model, true)
            end

            statements = [ create_table_statement(connection, model, properties) ]
            statements.concat(create_index_statements(model))
            statements.concat(create_unique_index_statements(model))
            statements.concat(create_sequence_statements(model))

            statements.each do |statement|
              command   = connection.create_command(statement)
              command.execute_non_query
            end
          end

        end

        true
      end

      # @api semipublic
      def destroy_model_storage(model, forced = false)
        table_name = model.storage_name(name)
        klass      = self.class
        truncate_or_delete = klass.auto_migrate_with
        if storage_exists?(table_name)
          if truncate_or_delete && !forced
            case truncate_or_delete
            when :truncate
              execute(truncate_table_statement(model))
            when :delete
              execute(delete_table_statement(model))
            else
              raise ArgumentError, "Unsupported auto_migrate_with option"
            end
            @truncated_tables ||= {}
            @truncated_tables[table_name] = true
          else
            execute(drop_table_statement(model))
            @truncated_tables[table_name] = nil if @truncated_tables
          end
        end
        # added destroy of sequences
        reset_sequences = klass.auto_migrate_reset_sequences
        table_is_truncated = @truncated_tables && @truncated_tables[table_name]
        unless truncate_or_delete && !reset_sequences && !forced
          if sequence_exists?(model_sequence_name(model))
            statement = if table_is_truncated && !forced
              reset_sequence_statement(model)
            else
              drop_sequence_statement(model)
            end
            execute(statement) if statement
          end
        end
        true
      end

      private

      def storage_has_all_fields?(table_name, properties)
        properties.map { |property| oracle_upcase(property.field) }.sort == storage_fields(table_name).sort
      end

      # If table or column name contains just lowercase characters then do uppercase
      # as uppercase version will be used in Oracle data dictionary tables
      def oracle_upcase(name)
        name =~ /[A-Z]/ ? name : name.upcase
      end

      module SQL #:nodoc:
#        private  ## This cannot be private for current migrations

        # @api private
        def schema_name
          @schema_name ||= select("SELECT SYS_CONTEXT('userenv','current_schema') FROM dual").first.freeze
        end

        # @api private
        def create_sequence_statements(model)
          name       = self.name
          table_name = model.storage_name(name)
          serial     = model.serial(name)

          statements = []
          if sequence_name = model_sequence_name(model)
            sequence_name = quote_name(sequence_name)
            column_name   = quote_name(serial.field)

            statements << DataMapper::Ext::String.compress_lines(<<-SQL)
              CREATE SEQUENCE #{sequence_name} NOCACHE
            SQL

            # create trigger only if custom sequence name was not specified
            unless serial.options[:sequence]
              statements << DataMapper::Ext::String.compress_lines(<<-SQL)
                CREATE OR REPLACE TRIGGER #{quote_name(default_trigger_name(table_name))}
                BEFORE INSERT ON #{quote_name(table_name)} FOR EACH ROW
                BEGIN
                  IF inserting THEN
                    IF :new.#{column_name} IS NULL THEN
                      SELECT #{sequence_name}.NEXTVAL INTO :new.#{column_name} FROM dual;
                    END IF;
                  END IF;
                END;
              SQL
            end
          end

          statements
        end

        # @api private
        def drop_sequence_statement(model)
          if sequence_name = model_sequence_name(model)
            "DROP SEQUENCE #{quote_name(sequence_name)}"
          else
            nil
          end
        end

        # @api private
        def reset_sequence_statement(model)
          if sequence_name = model_sequence_name(model)
            sequence_name = quote_name(sequence_name)
            DataMapper::Ext::String.compress_lines(<<-SQL)
            DECLARE
              cval   INTEGER;
            BEGIN
              SELECT #{sequence_name}.NEXTVAL INTO cval FROM dual;
              EXECUTE IMMEDIATE 'ALTER SEQUENCE #{sequence_name} INCREMENT BY -' || cval || ' MINVALUE 0';
              SELECT #{sequence_name}.NEXTVAL INTO cval FROM dual;
              EXECUTE IMMEDIATE 'ALTER SEQUENCE #{sequence_name} INCREMENT BY 1';
            END;
            SQL
          else
            nil
          end

        end

        # @api private
        def truncate_table_statement(model)
          "TRUNCATE TABLE #{quote_name(model.storage_name(name))}"
        end

        # @api private
        def delete_table_statement(model)
          "DELETE FROM #{quote_name(model.storage_name(name))}"
        end

        private

        def model_sequence_name(model)
          name       = self.name
          table_name = model.storage_name(name)
          serial     = model.serial(name)

          if serial
            serial.options[:sequence] || default_sequence_name(table_name)
          else
            nil
          end
        end

        def default_sequence_name(table_name)
          # truncate table name if necessary to fit in max length of identifier
          "#{table_name[0,self.class::IDENTIFIER_MAX_LENGTH-4]}_seq"
        end

        def default_trigger_name(table_name)
          # truncate table name if necessary to fit in max length of identifier
          "#{table_name[0,self.class::IDENTIFIER_MAX_LENGTH-4]}_pkt"
        end

        # @api private
        def add_column_statement
          'ADD'
        end

      end # module SQL

      include SQL

      module ClassMethods
        # Types for Oracle databases.
        #
        # @return [Hash] types for Oracle databases.
        #
        # @api private
        def type_map
          length    = Property::String::DEFAULT_LENGTH
          precision = Property::Numeric::DEFAULT_PRECISION
          scale     = Property::Decimal::DEFAULT_SCALE

          @type_map ||= {
            Integer        => { :primitive => 'NUMBER',   :precision => precision, :scale => 0   },
            String         => { :primitive => 'VARCHAR2', :length => length                      },
            Class          => { :primitive => 'VARCHAR2', :length => length                      },
            BigDecimal     => { :primitive => 'NUMBER',   :precision => precision, :scale => nil },
            Float          => { :primitive => 'BINARY_FLOAT',                                    },
            DateTime       => { :primitive => 'DATE'                                             },
            Date           => { :primitive => 'DATE'                                             },
            Time           => { :primitive => 'DATE'                                             },
            TrueClass      => { :primitive => 'NUMBER',  :precision => 1, :scale => 0            },
            Property::Text => { :primitive => 'CLOB'                                             },
          }.freeze
        end

        # Use table truncate or delete for auto_migrate! to speed up test execution
        #
        # @param [Symbol] :truncate, :delete or :drop_and_create (or nil)
        #   do not specify parameter to return current value
        #
        # @return [Symbol] current value of auto_migrate_with option (nil returned for :drop_and_create)
        #
        # @api semipublic
        def auto_migrate_with(value = :not_specified)
          return @auto_migrate_with if value == :not_specified
          value = nil if value == :drop_and_create
          raise ArgumentError unless [nil, :truncate, :delete].include?(value)
          @auto_migrate_with = value
        end

        # Set if sequences will or will not be reset during auto_migrate!
        #
        # @param [TrueClass, FalseClass] reset sequences?
        #   do not specify parameter to return current value
        #
        # @return [Symbol] current value of auto_migrate_reset_sequences option (default value is true)
        #
        # @api semipublic
        def auto_migrate_reset_sequences(value = :not_specified)
          return @auto_migrate_reset_sequences.nil? ? true : @auto_migrate_reset_sequences if value == :not_specified
          raise ArgumentError unless [true, false].include?(value)
          @auto_migrate_reset_sequences = value
        end

      end

    end
  end
end
