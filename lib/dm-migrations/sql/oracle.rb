require 'dm-migrations/sql/table'

module SQL
  module Oracle

    def change_column_type_statement(name, column)
      "ALTER TABLE #{quote_name(name)} MODIFY ( #{column.to_sql} )"
    end

  end
end