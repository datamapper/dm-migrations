require 'dm-migrations/auto_migration'
require 'dm-migrations/adapters/dm-do-adapter'

module DataMapper
  module Migrations
    module PostgresAdapter

      include DataObjectsAdapter

      # @api private
      def self.included(base)
        base.extend DataObjectsAdapter::ClassMethods
        base.extend ClassMethods
      end

      # @api semipublic
      def upgrade_model_storage(model)
        without_notices { super }
      end

      # @api semipublic
      def create_model_storage(model)
        without_notices { super }
      end

      # @api semipublic
      def destroy_model_storage(model)
        if supports_drop_table_if_exists?
          without_notices { super }
        else
          super
        end
      end

      module SQL #:nodoc:
#        private  ## This cannot be private for current migrations

        # @api private
        def supports_drop_table_if_exists?
          @supports_drop_table_if_exists ||= postgres_version >= '8.2'
        end

        # @api private
        def schema_name
          @schema_name ||= select('SELECT current_schema()').first.freeze
        end

        # @api private
        def postgres_version
          @postgres_version ||= select('SELECT version()').first.split[1].freeze
        end

        # @api private
        def without_notices
          # execute the block with NOTICE messages disabled
          begin
            execute('SET client_min_messages = warning')
            yield
          ensure
            execute('RESET client_min_messages')
          end
        end

        # @api private
        def property_schema_hash(property)
          schema = super

          primitive = property.primitive

          # Postgres does not support precision and scale for Float
          if primitive == Float
            schema.delete(:precision)
            schema.delete(:scale)
          end

          if property.kind_of?(Property::Integer)
            min = property.min
            max = property.max

            schema[:primitive] = integer_column_statement(min..max) if min && max
          end

          if schema[:serial]
            schema[:primitive] = serial_column_statement(min..max)
          end

          schema
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

          if    min >= -smallint && max < smallint then 'SMALLINT'
          elsif min >= -integer  && max < integer  then 'INTEGER'
          elsif min >= -bigint   && max < bigint   then 'BIGINT'
          else
            raise ArgumentError, "min #{min} and max #{max} exceeds supported range"
          end
        end

        # Return SQL statement for the serial column
        #
        # @param [Integer] max
        #   the max allowed integer
        #
        # @return [String]
        #   the statement to create the serial column
        #
        # @api private
        def serial_column_statement(range)
          max = range.last

          if    max.nil? || max < 2**31 then 'SERIAL'
          elsif             max < 2**63 then 'BIGSERIAL'
          else
            raise ArgumentError, "min #{range.first} and max #{max} exceeds supported range"
          end
        end
      end # module SQL

      include SQL

      module ClassMethods
        # Types for PostgreSQL databases.
        #
        # @return [Hash] types for PostgreSQL databases.
        #
        # @api private
        def type_map
          precision = Property::Numeric.precision
          scale     = Property::Decimal.scale

          super.merge(
            Property::Binary => { :primitive => 'BYTEA'                                                      },
            BigDecimal       => { :primitive => 'NUMERIC',          :precision => precision, :scale => scale },
            Float            => { :primitive => 'DOUBLE PRECISION'                                           }
          ).freeze
        end
      end

    end
  end
end
