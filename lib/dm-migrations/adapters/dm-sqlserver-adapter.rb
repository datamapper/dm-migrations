require 'dm-migrations/auto_migration'
require 'dm-migrations/adapters/dm-do-adapter'

module DataMapper
  module Migrations
    module SqlserverAdapter

      DEFAULT_CHARACTER_SET = 'utf8'.freeze

      include DataObjectsAdapter

      # @api private
      def self.included(base)
        base.extend DataObjectsAdapter::ClassMethods
        base.extend ClassMethods
      end

      # @api semipublic
      def storage_exists?(storage_name)
        select("SELECT name FROM sysobjects WHERE name LIKE ?", storage_name).first == storage_name
      end

      # @api semipublic
      def field_exists?(storage_name, field_name)
        result = select("SELECT c.name FROM sysobjects as o JOIN syscolumns AS c ON o.id = c.id WHERE o.name = #{quote_name(storage_name)} AND c.name LIKE ?", field_name).first
        result ? result.field == field_name : false
      end

      module SQL #:nodoc:
#        private  ## This cannot be private for current migrations

        # @api private
        def supports_serial?
          true
        end

        # @api private
        def supports_drop_table_if_exists?
          false
        end

        # @api private
        def schema_name
          # TODO: is there a cleaner way to find out the current DB we are connected to?
          @options[:path].split('/').last
        end

        # TODO: update dkubb/dm-more/dm-migrations to use schema_name and remove this

        alias_method :db_name, :schema_name

        # @api private
        def create_table_statement(connection, model, properties)
          statement = DataMapper::Ext::String.compress_lines(<<-SQL)
            CREATE TABLE #{quote_name(model.storage_name(name))}
            (#{properties.map { |property| property_schema_statement(connection, property_schema_hash(property)) }.join(', ')}
          SQL

          unless properties.any? { |property| property.serial? }
            statement << ", PRIMARY KEY(#{properties.key.map { |property| quote_name(property.field) }.join(', ')})"
          end

          statement << ')'
          statement
        end

        # @api private
        def property_schema_hash(property)
          schema = super

          if property.kind_of?(Property::Integer)
            min = property.min
            max = property.max

            schema[:primitive] = integer_column_statement(min..max) if min && max
          end

          if schema[:primitive] == 'TEXT'
            schema.delete(:default)
          end

          schema
        end

        # @api private
        def property_schema_statement(connection, schema)
          if supports_serial? && schema[:serial]
            statement = quote_name(schema[:name])
            statement << " #{schema[:primitive]}"

            length = schema[:length]

            if schema[:precision] && schema[:scale]
              statement << "(#{[ :precision, :scale ].map { |key| connection.quote_value(schema[key]) }.join(', ')})"
            elsif length
              statement << "(#{connection.quote_value(length)})"
            end

            statement << ' IDENTITY'
          else
            statement = super
          end

          statement
        end

        # @api private
        def character_set
          @character_set ||= show_variable('character_set_connection') || DEFAULT_CHARACTER_SET
        end

        # @api private
        def collation
          @collation ||= show_variable('collation_connection') || DEFAULT_COLLATION
        end

        # @api private
        def show_variable(name)
          raise "SqlserverAdapter#show_variable: Not implemented"
        end

        private

        # Return SQL statement for the integer column
        #
        # @param [Range] range
        #   the min/max allowed integers
        #
        # @return [String]
        #   the statement to create the integer column
        #
        # @api private
        def integer_column_statement(range)
          min = range.first
          max = range.last

          smallint = 2**15
          integer  = 2**31
          bigint   = 2**63

          if    min >= 0         && max < 2**8     then 'TINYINT'
          elsif min >= -smallint && max < smallint then 'SMALLINT'
          elsif min >= -integer  && max < integer  then 'INT'
          elsif min >= -bigint   && max < bigint   then 'BIGINT'
          else
            raise ArgumentError, "min #{min} and max #{max} exceeds supported range"
          end
        end

      end # module SQL

      include SQL

      module ClassMethods
        # Types for Sqlserver databases.
        #
        # @return [Hash] types for Sqlserver databases.
        #
        # @api private
        def type_map
          length    = Property::String::DEFAULT_LENGTH
          precision = Property::Numeric::DEFAULT_PRECISION
          scale     = Property::Decimal::DEFAULT_SCALE

          @type_map ||= super.merge(
            DateTime       => { :primitive => 'DATETIME'                                         },
            Date           => { :primitive => 'SMALLDATETIME'                                    },
            Time           => { :primitive => 'SMALLDATETIME'                                    },
            TrueClass      => { :primitive => 'BIT',                                             },
            Property::Text => { :primitive => 'NVARCHAR', :length => 'max'                       }
          ).freeze
        end
      end

    end
  end
end
