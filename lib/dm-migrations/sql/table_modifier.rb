module SQL
  class TableModifier
    extend DataMapper::Property::Lookup

    attr_accessor :table_name, :opts, :statements, :adapter

    def initialize(adapter, table_name, opts = {}, &block)
      @adapter = adapter
      @table_name = table_name.to_s
      @opts = (opts)

      @statements = []

      self.instance_eval &block
    end

    def add_column(name, type, opts = {})
      column = SQL::TableCreator::Column.new(@adapter, name, type, opts)
      @statements << "ALTER TABLE #{quoted_table_name} ADD COLUMN #{column.to_sql}"
    end

    def foreign_key_exists?(constraint_name)
      execute "SELECT TRUE FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_SCHEMA = #{quoted_table_name} AND CONSTRAINT_NAME = '#{quote_column_name(@table_name+'_'+constraint_name.to_s.gsub('_id', '')+'_fk')}'"    
    end

    def add_foreign_key(column, reference, reference_id = 'id')
      @statements << "ALTER TABLE #{quoted_table_name} " +
                                  "ADD CONSTRAINT #{quote_column_name(@table_name+'_'+reference.to_s.gsub('_id', '')+'_fk')} " +
                                  "FOREIGN KEY (#{quote_column_name(column)}) " +
                                  "REFERENCES #{quote_column_name(reference)} (#{quote_column_name(reference_id)}) " +
                                  "ON DELETE NO ACTION ON UPDATE NO ACTION"
    end

    def drop_foreign_key(constraint_name)
      fk_name = quote_column_name(@table_name+'_'+constraint_name.to_s.gsub('_id', '')+'_fk')
      @statements << "ALTER TABLE #{quoted_table_name} DROP FOREIGN KEY #{fk_name}"
      @statements << "ALTER TABLE #{quoted_table_name} DROP INDEX #{fk_name}"
    end

    def drop_column(name)
      # raise NotImplemented for SQLite3. Can't ALTER TABLE, need to copy table.
      # We'd have to inspect it, and we can't, since we aren't executing any queries yet.
      # TODO instead of building the SQL queries when executing the block, create AddColumn,
      # AlterColumn and DropColumn objects that get #to_sql'd
      if name.is_a?(Array)
        name.each{ |n| drop_column(n) }
      else
        @statements << "ALTER TABLE #{quoted_table_name} DROP COLUMN #{quote_column_name(name)}"
      end
    end
    alias_method :drop_columns, :drop_column

    def rename_column(name, new_name, opts = {})
      # raise NotImplemented for SQLite3
      @statements << @adapter.rename_column_type_statement(table_name, name, new_name)
    end

    def change_column(name, type, opts = {})
      column = SQL::TableCreator::Column.new(@adapter, name, type, opts)
      @statements << @adapter.change_column_type_statement(table_name, column)
    end

    def quote_column_name(name)
      @adapter.send(:quote_name, name.to_s)
    end

    def quoted_table_name
      @adapter.send(:quote_name, table_name)
    end

    def to_sql
      @statements.join(';')
    end
  end
end
