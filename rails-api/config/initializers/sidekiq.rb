# config/initializers/sidekiq.rb
require 'sidekiq'

# Configure Redis connection
redis_config = {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
  network_timeout: 5
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
  
  # Set concurrency based on database pool size
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 10).to_i
  
  # Server-side middleware configuration
  # Note: Multi-tenancy context is handled in ApplicationWorker
  
  # Error handling
  config.error_handlers << proc do |ex, ctx_hash|
    Rails.logger.error "Sidekiq error: #{ex.message}"
    Rails.logger.error ex.backtrace.join("\n")
  end
  
  # Death handlers for jobs that exhaust retries
  config.death_handlers << proc do |job, ex|
    Rails.logger.error "Job #{job['class']} with args #{job['args']} died: #{ex.message}"
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
  
  # Client-side middleware configuration
  # Note: Multi-tenancy context is handled in ApplicationWorker
end

# Configure Sidekiq logging
if Rails.env.development?
  Sidekiq.configure_server do |config|
    config.logger.level = Logger::INFO
  end
end