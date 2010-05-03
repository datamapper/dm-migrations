shared_examples_for "require 'dm-migrations'" do

  it "should include the migration api in the DataMapper namespace" do
    DataMapper.respond_to?(:migrate!                ).should be_true
    DataMapper.respond_to?(:auto_migrate!           ).should be_true
    DataMapper.respond_to?(:auto_upgrade!           ).should be_true
    DataMapper.respond_to?(:auto_migrate_up!,   true).should be_true
    DataMapper.respond_to?(:auto_migrate_down!, true).should be_true
  end

  %w[Repository Model].each do |name|
    it "should include the migration api in DataMapper::#{name}" do
      (DataMapper.const_get(name) < DataMapper::Migrations.const_get(name)).should be_true
    end
  end

  it "should include the migration api into the adapter" do
    @adapter.respond_to?(:storage_exists?      ).should be_true
    @adapter.respond_to?(:field_exists?        ).should be_true
    @adapter.respond_to?(:upgrade_model_storage).should be_true
    @adapter.respond_to?(:create_model_storage ).should be_true
    @adapter.respond_to?(:destroy_model_storage).should be_true
  end

end
