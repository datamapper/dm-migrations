require 'spec_helper'

describe "SQL generation" do

  supported_by :postgres, :mysql, :sqlite, :oracle, :sqlserver do

    describe DataMapper::Migration, "#create_table helper" do
      before :all do

        @adapter    = DataMapper::Spec.adapter
        @repository = DataMapper.repository(@adapter.name)

        case DataMapper::Spec.adapter_name.to_sym
        when :sqlite   then @adapter.extend(SQL::Sqlite)
        when :mysql    then @adapter.extend(SQL::Mysql)
        when :postgres then @adapter.extend(SQL::Postgres)
        end

      end

      before do
        @creator = DataMapper::Migration::TableCreator.new(@adapter, :people) do
          column :id,          DataMapper::Property::Serial
          column :name,        'VARCHAR(50)', :allow_nil => false
          column :long_string, String, :size => 200
        end
      end

      it "should have a #create_table helper" do
        @migration = DataMapper::Migration.new(1, :create_people_table, :verbose => false) { }
        @migration.should respond_to(:create_table)
      end

      it "should have a table_name" do
        @creator.table_name.should == "people"
      end

      it "should have an adapter" do
        @creator.instance_eval("@adapter").should == @adapter
      end

      it "should have an options hash" do
        @creator.opts.should be_kind_of(Hash)
        @creator.opts.should == {}
      end

      it "should have an array of columns" do
        @creator.instance_eval("@columns").should be_kind_of(Array)
        @creator.instance_eval("@columns").size.should == 3
        @creator.instance_eval("@columns").first.should be_kind_of(DataMapper::Migration::TableCreator::Column)
      end

      it "should quote the table name for the adapter" do
        @creator.quoted_table_name.should == (DataMapper::Spec.adapter_name.to_sym == :mysql ? '`people`' : '"people"')
      end

      it "should allow for custom options" do
        columns = @creator.instance_eval("@columns")
        col = columns.detect{|c| c.name == "long_string"}
        col.instance_eval("@type").should include("200")
      end

      it "should generate a NOT NULL column when :allow_nil is false" do
        @creator.instance_eval("@columns")[1].type.should match(/NOT NULL/)
      end

      case DataMapper::Spec.adapter_name.to_sym
      when :mysql
        it "should create an InnoDB database for MySQL" do
          #can't get an exact == comparison here because character set and collation may differ per connection
          @creator.to_sql.should match(/^CREATE TABLE `people` \(`id` SERIAL PRIMARY KEY, `name` VARCHAR\(50\) NOT NULL, `long_string` VARCHAR\(200\)\) ENGINE = InnoDB CHARACTER SET \w+ COLLATE \w+\z/)
        end

        it "should allow for custom table creation options for MySQL" do
          opts = {
            :storage_engine => 'MyISAM',
            :character_set  => 'big5',
            :collation      => 'big5_chinese_ci',
          }

          creator = DataMapper::Migration::TableCreator.new(@adapter, :people, opts) do
            column :id, DataMapper::Property::Serial
          end

          creator.to_sql.should match(/^CREATE TABLE `people` \(`id` SERIAL PRIMARY KEY\) ENGINE = MyISAM CHARACTER SET big5 COLLATE big5_chinese_ci\z/)
        end

        it "should respect default storage engine types specified by the MySQL adapter" do
          adapter = DataMapper::Spec.adapter
          adapter.extend(SQL::Mysql)

          adapter.storage_engine = 'MyISAM'

          creator = DataMapper::Migration::TableCreator.new(adapter, :people) do
            column :id, DataMapper::Property::Serial
          end

          creator.to_sql.should match(/^CREATE TABLE `people` \(`id` SERIAL PRIMARY KEY\) ENGINE = MyISAM CHARACTER SET \w+ COLLATE \w+\z/)
        end

      when :postgres
        it "should output a CREATE TABLE statement when sent #to_sql" do
          @creator.to_sql.should == %q{CREATE TABLE "people" ("id" SERIAL PRIMARY KEY, "name" VARCHAR(50) NOT NULL, "long_string" VARCHAR(200))}
        end
      when :sqlite3
        it "should output a CREATE TABLE statement when sent #to_sql" do
          @creator.to_sql.should == %q{CREATE TABLE "people" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" VARCHAR(50) NOT NULL, "long_string" VARCHAR(200))}
        end
      end

      context 'when the default string length is modified' do
        before do
          @original = DataMapper::Property::String.length
          DataMapper::Property::String.length(255)

          @creator = DataMapper::Migration::TableCreator.new(@adapter, :people) do
            column :string, String
          end
        end

        after do
          DataMapper::Property::String.length(@original)
        end

        it 'uses the new length for the character column' do
          @creator.to_sql.should match(/CHAR\(255\)/)
        end
      end
    end

    describe DataMapper::Migration, "#modify_table helper" do
      before do
        @migration = DataMapper::Migration.new(1, :create_people_table, :verbose => false) { }

      end

      it "should have a #modify_table helper" do
        @migration.should respond_to(:modify_table)
      end

      case DataMapper::Spec.adapter_name.to_sym
      when :postgres
        before do
          @modifier = DataMapper::Migration::TableModifier.new(@adapter, :people) do
            change_column :name, 'VARCHAR(200)'
          end
        end

        it "should alter the column" do
          @modifier.to_sql.should == %q{ALTER TABLE "people" ALTER COLUMN "name" VARCHAR(200)}
        end
      end
    end

    describe DataMapper::Migration, "other helpers" do
      before do
        @migration = DataMapper::Migration.new(1, :create_people_table, :verbose => false) { }
      end

      it "should have a #drop_table helper" do
        @migration.should respond_to(:drop_table)
      end

    end

    describe DataMapper::Migration, "version tracking" do
      before(:each) do
        @migration = DataMapper::Migration.new(1, :create_people_table, :verbose => false) do
          up   { :ran_up }
          down { :ran_down }
        end

        @migration.send(:create_migration_info_table_if_needed)
      end

      after(:each) { DataMapper::Spec.adapter.execute("DROP TABLE migration_info") rescue nil }

      def insert_migration_record
        DataMapper::Spec.adapter.execute("INSERT INTO migration_info (migration_name) VALUES ('create_people_table')")
      end

      it "should know if the migration_info table exists" do
        @migration.send(:migration_info_table_exists?).should be(true)
      end

      it "should know if the migration_info table does not exist" do
        DataMapper::Spec.adapter.execute("DROP TABLE migration_info") rescue nil
        @migration.send(:migration_info_table_exists?).should be(false)
      end

      it "should be able to find the migration_info record for itself" do
        insert_migration_record
        @migration.send(:migration_record).should_not be_empty
      end

      it "should know if a migration needs_up?" do
        @migration.send(:needs_up?).should be(true)
        insert_migration_record
        @migration.send(:needs_up?).should be(false)
      end

      it "should know if a migration needs_down?" do
        @migration.send(:needs_down?).should be(false)
        insert_migration_record
        @migration.send(:needs_down?).should be(true)
      end

      it "should properly quote the migration_info table via the adapter for use in queries" do
        @migration.send(:migration_info_table).should == @migration.quote_table_name("migration_info")
      end

      it "should properly quote the migration_info.migration_name column via the adapter for use in queries" do
        @migration.send(:migration_name_column).should == @migration.quote_column_name("migration_name")
      end

      it "should properly quote the migration's name for use in queries"
      # TODO how to i call the adapter's #escape_sql method?

      it "should create the migration_info table if it doesn't exist" do
        DataMapper::Spec.adapter.execute("DROP TABLE migration_info")
        @migration.send(:migration_info_table_exists?).should be(false)
        @migration.send(:create_migration_info_table_if_needed)
        @migration.send(:migration_info_table_exists?).should be(true)
      end

      it "should insert a record into the migration_info table on up" do
        @migration.send(:migration_record).should be_empty
        @migration.perform_up.should == :ran_up
        @migration.send(:migration_record).should_not be_empty
      end

      it "should remove a record from the migration_info table on down" do
        insert_migration_record
        @migration.send(:migration_record).should_not be_empty
        @migration.perform_down.should == :ran_down
        @migration.send(:migration_record).should be_empty
      end

      it "should not run the up action if the record exists in the table" do
        insert_migration_record
        @migration.perform_up.should_not == :ran_up
      end

      it "should not run the down action if the record does not exist in the table" do
        @migration.perform_down.should_not == :ran_down
      end

    end
  end
end
