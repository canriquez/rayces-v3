# frozen_string_literal: true

# BootGuard provides safe checks for database and model availability during Rails boot
# Useful for initializers that need to reference models or database state
module BootGuard
  class << self
    # Check if database is available and ready for queries
    # @return [Boolean] true if database connection can be established
    def db_ready?
      return @db_ready if defined?(@db_ready)
      
      @db_ready = begin
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.active?
        end
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad => e
        Rails.logger.warn "[BootGuard] Database not ready: #{e.class} - #{e.message}"
        false
      end
    end

    # Check if a specific model is defined and its table exists
    # @param model_name [String, Symbol] The model class name (e.g., 'Organization')
    # @return [Boolean] true if model is defined and table exists
    def model_ready?(model_name)
      return false unless db_ready?
      
      model_class = model_name.to_s.constantize
      model_class.table_exists?
    rescue NameError => e
      Rails.logger.warn "[BootGuard] Model #{model_name} not defined: #{e.message}"
      false
    rescue => e
      Rails.logger.warn "[BootGuard] Error checking model #{model_name}: #{e.class} - #{e.message}"
      false
    end

    # Execute a block only if database and models are ready
    # @param required_models [Array<String, Symbol>] List of required model names
    # @yield Block to execute if all requirements are met
    # @return [Object, nil] Result of block execution or nil if requirements not met
    def when_ready(*required_models, &block)
      return unless db_ready?
      
      if required_models.any?
        return unless required_models.all? { |model| model_ready?(model) }
      end
      
      yield
    rescue => e
      Rails.logger.error "[BootGuard] Error in when_ready block: #{e.class} - #{e.message}"
      nil
    end

    # Clear cached state (useful for testing)
    def reset!
      remove_instance_variable(:@db_ready) if defined?(@db_ready)
    end
  end
end