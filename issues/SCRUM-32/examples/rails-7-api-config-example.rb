# Rails 7 API Configuration Example
# This file demonstrates how to configure a Rails 7 API application
# with the necessary gems and settings for the Rayces booking platform

# config/application.rb
module RailsApi
  class Application < Rails::Application
    config.load_defaults 7.0
    
    # API-only mode configuration
    config.api_only = true
    
    # Set timezone configuration for multi-tenant consistency
    config.time_zone = 'UTC'
    
    # Configure Active Job with Sidekiq
    config.active_job.queue_adapter = :sidekiq
    
    # CORS configuration for frontend integration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end
    
    # Load path optimizations
    config.autoload_paths += %W(#{config.root}/app/policies)
    config.autoload_paths += %W(#{config.root}/app/workers)
    config.autoload_paths += %W(#{config.root}/app/serializers)
    
    # Configure eager loading for production
    config.eager_load = true if Rails.env.production?
    
    # Configure database connection pool
    config.active_record.establish_connection_on_boot = true
  end
end

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
  config.concurrency = 5
  
  # Configure error handling
  config.error_handlers << proc do |ex, ctx|
    Rails.logger.error "Sidekiq error: #{ex.message}"
    Rails.logger.error ex.backtrace.join("\n")
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV.fetch("DB_USER", "postgres") %>
  password: <%= ENV.fetch("DB_PASSWORD", "password") %>
  host: <%= ENV.fetch("DB_HOST", "localhost") %>
  port: <%= ENV.fetch("DB_PORT", "5432") %>

development:
  <<: *default
  database: rayces_development

test:
  <<: *default
  database: rayces_test

production:
  <<: *default
  database: rayces_production
  username: <%= ENV.fetch("DB_USER") %>
  password: <%= ENV.fetch("DB_PASSWORD") %>

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions
  include Pundit::Authorization
  
  # Multi-tenancy configuration
  set_current_tenant_by_subdomain(:organization, :subdomain)
  
  # Authorization verification
  after_action :verify_authorized, unless: :devise_controller?
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized
    render json: { error: 'Not authorized' }, status: :forbidden
  end
end

# Gemfile additions for Rails 7 API
gem 'rails', '~> 7.0'
gem 'acts_as_tenant', '~> 0.6.1'
gem 'pundit', '~> 2.3'
gem 'sidekiq', '~> 7.1'
gem 'redis', '~> 5.0'
gem 'aasm', '~> 5.5'
gem 'devise', '~> 4.9'
gem 'devise-jwt', '~> 0.11.0'
gem 'active_model_serializers', '~> 0.10.14'
gem 'rack-cors', '~> 2.0'
gem 'kaminari', '~> 1.2'

group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'rubocop-rails', '~> 2.20'
  gem 'brakeman', '~> 6.0'
end