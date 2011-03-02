require 'dm-migrations/auto_migration'

module DataMapper
  module Migrations

    module DataObjectsAdapter

      # Returns whether the storage_name exists.
      #
      # @param [String] storage_name
      #   a String defining the name of a storage, for example a table name.
      #
      # @return [Boolean]
      #   true if the storage exists
      #
      # @api semipublic
      def storage_exists?(storage_name)
        statement = DataMapper::Ext::String.compress_lines(<<-SQL)
          SELECT COUNT(*)
          FROM "information_schema"."tables"
          WHERE "table_type" = 'BASE TABLE'
          AND "table_schema" = ?
          AND "table_name" = ?
        SQL

        select(statement, schema_name, storage_name).first > 0
      end

      # Returns whether the field exists.
      #
      # @param [String] storage_name
      #   a String defining the name of a storage, for example a table name.
      # @param [String] field
      #   a String defining the name of a field, for example a column name.
      #
      # @return [Boolean]
      #   true if the field exists.
      #
      # @api semipublic
      def field_exists?(storage_name, column_name)
        statement = DataMapper::Ext::String.compress_lines(<<-SQL)
          SELECT COUNT(*)
          FROM "information_schema"."columns"
          WHERE "table_schema" = ?
          AND "table_name" = ?
          AND "column_name" = ?
        SQL

        select(statement, schema_name, storage_name, column_name).first > 0
      end

      # @api semipublic
      def upgrade_model_storage(model)
        name       = self.name
        properties = model.properties_with_subclasses(name)

        if success = create_model_storage(model)
          return properties
        end

        table_name = model.storage_name(name)

        with_connection do |connection|
          properties.map do |property|
            schema_hash = property_schema_hash(property)
            next if field_exists?(table_name, schema_hash[:name])

            statement = alter_table_add_column_statement(connection, table_name, schema_hash)
            command   = connection.create_command(statement)
            command.execute_non_query

            # For simple :index => true columns, add an appropriate index.
            # Upgrading doesn't know how to deal with complex indexes yet.
            if property.options[:index] === true
              statement = create_index_statement(model, property.name, [property.field])
              command   = connection.create_command(statement)
              command.execute_non_query
            end

            property
          end.compact
        end
      end

      # @api semipublic
      def create_model_storage(model)
        name       = self.name
        properties = model.properties_with_subclasses(name)

        return false if storage_exists?(model.storage_name(name))
        return false if properties.empty?

        with_connection do |connection|
          statements = [ create_table_statement(connection, model, properties) ]
          statements.concat(create_index_statements(model))
          statements.concat(create_unique_index_statements(model))

          statements.each do |statement|
            command   = connection.create_command(statement)
            command.execute_non_query
          end
        end

        true
      end

      # @api semipublic
      def destroy_model_storage(model)
        return true unless supports_drop_table_if_exists? || storage_exists?(model.storage_name(name))
        execute(drop_table_statement(model))
        true
      end

      module SQL #:nodoc:
#        private  ## This cannot be private for current migrations

        # Adapters that support AUTO INCREMENT fields for CREATE TABLE
        # statements should overwrite this to return true
        #
        # @api private
        def supports_serial?
          false
        end

        # @api private
        def supports_drop_table_if_exists?
          false
        end

        # @api private
        def schema_name
          raise NotImplementedError, "#{self.class}#schema_name not implemented"
        end

        # @api private
        def alter_table_add_column_statement(connection, table_name, schema_hash)
          "ALTER TABLE #{quote_name(table_name)} #{add_column_statement} #{property_schema_statement(connection, schema_hash)}"
        end

        # @api private
        def create_table_statement(connection, model, properties)
          statement = DataMapper::Ext::String.compress_lines(<<-SQL)
            CREATE TABLE #{quote_name(model.storage_name(name))}
            (#{properties.map { |property| property_schema_statement(connection, property_schema_hash(property)) }.join(', ')},
            PRIMARY KEY(#{ properties.key.map { |property| quote_name(property.field) }.join(', ')}))
          SQL

          statement
        end

        # @api private
        def drop_table_statement(model)
          table_name = quote_name(model.storage_name(name))
          if supports_drop_table_if_exists?
            "DROP TABLE IF EXISTS #{table_name}"
          else
            "DROP TABLE #{table_name}"
          end
        end

        # @api private
        def create_index_statements(model)
          name       = self.name
          table_name = model.storage_name(name)

          indexes(model).map do |index_name, fields|
            create_index_statement(model, index_name, fields)
          end
        end

        # @api private
        def create_index_statement(model, index_name, fields)
          table_name = model.storage_name(name)

          DataMapper::Ext::String.compress_lines(<<-SQL)
            CREATE INDEX #{quote_name("index_#{table_name}_#{index_name}")} ON
            #{quote_name(table_name)} (#{fields.map { |field| quote_name(field) }.join(', ')})
          SQL
        end

        # @api private
        def create_unique_index_statements(model)
          name           = self.name
          table_name     = model.storage_name(name)
          key            = model.key(name).map { |property| property.field }
          unique_indexes = unique_indexes(model).reject { |index_name, fields| fields == key }

          unique_indexes.map do |index_name, fields|
            DataMapper::Ext::String.compress_lines(<<-SQL)
              CREATE UNIQUE INDEX #{quote_name("unique_#{table_name}_#{index_name}")} ON
              #{quote_name(table_name)} (#{fields.map { |field| quote_name(field) }.join(', ')})
            SQL
          end
        end

        # @api private
        def property_schema_hash(property)
          primitive = property.primitive
          type_map  = self.class.type_map

          schema = (type_map[property.class] || type_map[primitive]).merge(:name => property.field)

          schema_primitive = schema[:primitive]

          if primitive == String && schema_primitive != 'TEXT' && schema_primitive != 'CLOB' && schema_primitive != 'NVARCHAR'
            schema[:length] = property.length
          elsif primitive == BigDecimal || primitive == Float
            schema[:precision] = property.precision
            schema[:scale]     = property.scale
          end

          schema[:allow_nil] = property.allow_nil?
          schema[:serial]    = property.serial?

          default = property.default

          if default.nil? || default.respond_to?(:call)
            # remove the default if the property does not allow nil
            schema.delete(:default) unless schema[:allow_nil]
          else
            schema[:default] = property.dump(default)
          end

          schema
        end

        # @api private
        def property_schema_statement(connection, schema)
          statement = quote_name(schema[:name])
          statement << " #{schema[:primitive]}"

          length = schema[:length]

          if schema[:precision] && schema[:scale]
            statement << "(#{[ :precision, :scale ].map { |key| connection.quote_value(schema[key]) }.join(', ')})"
          elsif length == 'max'
            statement << '(max)'
          elsif length
            statement << "(#{connection.quote_value(length)})"
          end

          statement << " DEFAULT #{connection.quote_value(schema[:default])}" if schema.key?(:default)
          statement << ' NOT NULL' unless schema[:allow_nil]
          statement
        end

        # @api private
        def indexes(model)
          model.properties(name).indexes
        end

        # @api private
        def unique_indexes(model)
          model.properties(name).unique_indexes
        end

        # @api private
        def add_column_statement
          'ADD COLUMN'
        end
      end # module SQL

      include SQL

      module ClassMethods
        # Default types for all data object based adapters.
        #
        # @return [Hash] default types for data objects adapters.
        #
        # @api private
        def type_map
          length    = Property::String::DEFAULT_LENGTH
          precision = Property::Numeric::DEFAULT_PRECISION
          scale     = Property::Decimal::DEFAULT_SCALE

          @type_map ||= {
            Property::Binary => { :primitive => 'BLOB'                                              },
            Object           => { :primitive => 'TEXT'                                              },
            Integer          => { :primitive => 'INTEGER'                                           },
            String           => { :primitive => 'VARCHAR', :length => length                        },
            Class            => { :primitive => 'VARCHAR', :length => length                        },
            BigDecimal       => { :primitive => 'DECIMAL', :precision => precision, :scale => scale },
            Float            => { :primitive => 'FLOAT',   :precision => precision                  },
            DateTime         => { :primitive => 'TIMESTAMP'                                         },
            Date             => { :primitive => 'DATE'                                              },
            Time             => { :primitive => 'TIMESTAMP'                                         },
            TrueClass        => { :primitive => 'BOOLEAN'                                           },
            Property::Text   => { :primitive => 'TEXT'                                              },
          }.freeze
        end
      end
    end

  end
end
