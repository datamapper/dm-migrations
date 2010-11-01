require 'spec_helper'

# a dummy class to include the module into
class PostgresExtension
  include SQL::Postgres
end

describe "Postgres Extensions" do
  before do
    @pe = PostgresExtension.new
  end

  it 'should support schema-level transactions' do
    @pe.supports_schema_transactions?.should be(true)
  end

  it 'should support the serial column attribute' do
    @pe.supports_serial?.should be(true)
  end

  it 'should create a table object from the name' do
    table = mock('Postgres Table')
    SQL::Postgres::Table.should_receive(:new).with(@pe, 'users').and_return(table)

    @pe.table('users').should == table
  end

  describe 'recreating the database' do
  end

  describe 'Table' do
    before do
      @cs1 = mock('Column Struct')
      @cs2 = mock('Column Struct')
      @adapter = mock('adapter', :select => [])
      @adapter.stub!(:query_table).with('users').and_return([@cs1, @cs2])

      @col1 = mock('Postgres Column')
      @col2 = mock('Postgres Column')
    end

    it 'should initialize columns by querying the table' do
      SQL::Postgres::Column.should_receive(:new).with(@cs1).and_return(@col1)
      SQL::Postgres::Column.should_receive(:new).with(@cs2).and_return(@col2)
      @adapter.should_receive(:query_table).with('users').and_return([@cs1,@cs2])
      SQL::Postgres::Table.new(@adapter, 'users')
    end

    it 'should create Postgres Column objects from the returned column structs' do
      SQL::Postgres::Column.should_receive(:new).with(@cs1).and_return(@col1)
      SQL::Postgres::Column.should_receive(:new).with(@cs2).and_return(@col2)
      SQL::Postgres::Table.new(@adapter, 'users')
    end

    it 'should set the @columns to the looked-up columns' do
      SQL::Postgres::Column.should_receive(:new).with(@cs1).and_return(@col1)
      SQL::Postgres::Column.should_receive(:new).with(@cs2).and_return(@col2)
      t = SQL::Postgres::Table.new(@adapter, 'users')
      t.columns.should == [@col1, @col2]
    end

    describe '#query_column_constraints' do

    end

  end

  describe 'Column' do
    before do
      @cs = mock('Struct',
                 :column_name     => 'id',
                 :data_type       => 'integer',
                 :column_default  => 123,
                 :is_nullable     => 'NO')
      @c = SQL::Postgres::Column.new(@cs)
    end

    it 'should set the name from the column_name value' do
      @c.name.should == 'id'
    end

    it 'should set the type from the data_type value' do
      @c.type.should == 'integer'
    end

    it 'should set the default_value from the column_default value' do
      @c.default_value.should == 123
    end

    it 'should set not_null based on the is_nullable value' do
      @c.not_null.should == true
    end

  end


end
