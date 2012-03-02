require 'dm-migrations/sql/table'

module SQL
  module Sqlserver

    def change_column_type_statement(name, column)
      "ALTER TABLE #{quote_name(name)} ALTER COLUMN #{column.to_sql}"
    end
    
  end
end