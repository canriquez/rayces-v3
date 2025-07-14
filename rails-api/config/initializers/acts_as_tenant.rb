# config/initializers/acts_as_tenant.rb

# Configure acts_as_tenant only for non-test environments
unless Rails.env.test?
  ActsAsTenant.configure do |config|
    config.require_tenant = true if Rails.env.development?
    config.require_tenant = true if Rails.env.production?
  end
end

# Configure Sidekiq middleware for multi-tenancy
# Note: ActsAsTenant 0.6 doesn't include built-in Sidekiq middleware
# We'll implement custom tenant context preservation in ApplicationWorker