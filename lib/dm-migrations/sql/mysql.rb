require 'dm-migrations/sql/table'

module SQL
  module Mysql

    def supports_schema_transactions?
      false
    end

    def table(table_name)
      SQL::Mysql::Table.new(self, table_name)
    end

    def recreate_database
      execute "DROP DATABASE #{schema_name}"
      execute "CREATE DATABASE #{schema_name}"
      execute "USE #{schema_name}"
    end

    def supports_serial?
      true
    end

    def table_options(opts)
      opt_engine    = opts[:storage_engine] || storage_engine
      opt_char_set  = opts[:character_set] || character_set
      opt_collation = opts[:collation] || collation

      " ENGINE = #{opt_engine} CHARACTER SET #{opt_char_set} COLLATE #{opt_collation}"
    end

    def property_schema_statement(connection, schema)
      if supports_serial? && schema[:serial]
        statement = "#{schema[:quote_column_name]} SERIAL PRIMARY KEY"
      else
        super
      end
    end

    def change_column_type_statement(name, column)
      "ALTER TABLE #{quote_name(name)} MODIFY COLUMN #{column.to_sql}"
    end

    def rename_column_type_statement(table_name, old_col, new_col)
      table_info = select("SHOW COLUMNS FROM #{quote_name(table_name)} LIKE ?", old_col).first
      "ALTER TABLE #{quote_name(table_name)} CHANGE #{quote_name(old_col)} #{quote_name(new_col)} #{table_info.type}"
    end

    class Table
      def initialize(adapter, table_name)
        @columns = []
        adapter.table_info(table_name).each do |col_struct|
          @columns << SQL::Mysql::Column.new(col_struct)
        end
      end
    end

    class Column
      def initialize(col_struct)
        @name, @type, @default_value, @primary_key = col_struct.name, col_struct.type, col_struct.dflt_value, col_struct.pk

        @not_null = col_struct.notnull == 0
      end
    end
  end
end
