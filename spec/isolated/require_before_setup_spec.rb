require 'spec'
require 'isolated/require_spec'
require 'dm-core/spec/setup'

# To really test this behavior, this spec needs to be run in isolation and not
# as part of the typical rake spec run, which requires dm-transactions upfront

if %w[ postgres mysql sqlite oracle sqlserver ].include?(ENV['ADAPTER'])

  describe "require 'dm-migrations' before calling DataMapper.setup" do

    before(:all) do

      require 'dm-migrations'
      @adapter = DataMapper::Spec.adapter

      class ::Person
        include DataMapper::Resource
        property :id, Serial
      end

      @model   = Person

    end

    it_should_behave_like "require 'dm-migrations'"

  end

end
