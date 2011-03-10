require 'dm-core'

module DataMapper
  module Migrations
    module Repository
      # Determine whether a particular named storage exists in this repository
      #
      # @param [String]
      #   storage_name name of the storage to test for
      #
      # @return [Boolean]
      #   true if the data-store +storage_name+ exists
      #
      # @api semipublic
      def storage_exists?(storage_name)
        adapter = self.adapter
        if adapter.respond_to?(:storage_exists?)
          adapter.storage_exists?(storage_name)
        end
      end

      # @api semipublic
      def upgrade_model_storage(model)
        adapter = self.adapter
        if adapter.respond_to?(:upgrade_model_storage)
          adapter.upgrade_model_storage(model)
        end
      end

      # @api semipublic
      def create_model_storage(model)
        adapter = self.adapter
        if adapter.respond_to?(:create_model_storage)
          adapter.create_model_storage(model)
        end
      end

      # @api semipublic
      def destroy_model_storage(model)
        adapter = self.adapter
        if adapter.respond_to?(:destroy_model_storage)
          adapter.destroy_model_storage(model)
        end
      end

      # Destructively automigrates the data-store to match the model.
      # First migrates all models down and then up.
      # REPEAT: THIS IS DESTRUCTIVE
      #
      # @api public
      def auto_migrate!
        DataMapper.auto_migrate!(name)
      end

      # Safely migrates the data-store to match the model
      # preserving data already in the data-store
      #
      # @api public
      def auto_upgrade!
        DataMapper.auto_upgrade!(name)
      end
    end # module Repository
  end # module Migrations
end # module DataMapper
