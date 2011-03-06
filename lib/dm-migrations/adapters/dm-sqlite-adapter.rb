require 'dm-migrations/auto_migration'
require 'dm-migrations/adapters/dm-do-adapter'

module DataMapper
  module Migrations
    module SqliteAdapter

      include DataObjectsAdapter

      # @api private
      def self.included(base)
        base.extend DataObjectsAdapter::ClassMethods
        base.extend ClassMethods
      end

      # @api semipublic
      def storage_exists?(storage_name)
        table_info(storage_name).any?
      end

      # @api semipublic
      def field_exists?(storage_name, column_name)
        table_info(storage_name).any? do |row|
          row.name == column_name
        end
      end

      module SQL #:nodoc:
#        private  ## This cannot be private for current migrations

        # @api private
        def supports_serial?
          @supports_serial ||= sqlite_version >= '3.1.0'
        end

        # @api private
        def supports_drop_table_if_exists?
          @supports_drop_table_if_exists ||= sqlite_version >= '3.3.0'
        end

        # @api private
        def table_info(table_name)
          select("PRAGMA table_info(#{quote_name(table_name)})")
        end

        # @api private
        def create_table_statement(connection, model, properties)
          statement = DataMapper::Ext::String.compress_lines(<<-SQL)
            CREATE TABLE #{quote_name(model.storage_name(name))}
            (#{properties.map { |property| property_schema_statement(connection, property_schema_hash(property)) }.join(', ')}
          SQL

          # skip adding the primary key if one of the columns is serial.  In
          # SQLite the serial column must be the primary key, so it has already
          # been defined
          unless properties.any? { |property| property.serial? }
            statement << ", PRIMARY KEY(#{properties.key.map { |property| quote_name(property.field) }.join(', ')})"
          end

          statement << ')'
          statement
        end

        # @api private
        def property_schema_statement(connection, schema)
          statement = super

          if supports_serial? && schema[:serial]
            statement << ' PRIMARY KEY AUTOINCREMENT'
          end

          statement
        end

        # @api private
        def sqlite_version
          @sqlite_version ||= select('SELECT sqlite_version(*)').first.freeze
        end
      end # module SQL

      include SQL

      module ClassMethods
        # Types for SQLite 3 databases.
        #
        # @return [Hash] types for SQLite 3 databases.
        #
        # @api private
        def type_map
          @type_map ||= super.merge(Class => { :primitive => 'VARCHAR' }).freeze
        end
      end

    end
  end
end
