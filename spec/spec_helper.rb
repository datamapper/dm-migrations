require 'dm-migrations'
require 'dm-migrations/migration_runner'

require 'dm-core/spec/setup'
require 'dm-core/spec/lib/adapter_helpers'
require 'dm-core/spec/lib/spec_helper'

Spec::Runner.configure do |config|

  config.extend(DataMapper::Spec::Adapters::Helpers)

  config.after :all do
    DataMapper::Spec.cleanup_models
  end

end
