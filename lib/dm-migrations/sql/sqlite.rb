require 'dm-migrations/sql/table'

require 'fileutils'

module SQL
  module Sqlite

    def supports_schema_transactions?
      true
    end

    def table(table_name)
      SQL::Sqlite::Table.new(self, table_name)
    end

    def recreate_database
      DataMapper.logger.info "Dropping #{@uri.path}"
      FileUtils.rm_f(@uri.path)
      # do nothing, sqlite will automatically create the database file
    end

    def table_options(opts)
      ''
    end

    def supports_serial?
      true
    end

    def change_column_type_statement(*args)
      raise NotImplementedError
    end

    def rename_column_type_statement(table_name, old_col, new_col)
      raise NotImplementedError
    end


    class Table < SQL::Table
      def initialize(adapter, table_name)
        @columns = []
        adapter.table_info(table_name).each do |col_struct|
          @columns << SQL::Sqlite::Column.new(col_struct)
        end
      end
    end

    class Column < SQL::Column
      def initialize(col_struct)
        @name, @type, @default_value, @primary_key = col_struct.name, col_struct.type, col_struct.dflt_value, col_struct.pk

        @not_null = col_struct.notnull == 0
      end
    end
  end
end
