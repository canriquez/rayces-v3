# config/initializers/acts_as_tenant.rb

# Load BootGuard for safe database checks
require_relative '../../lib/boot_guard'

# 🛡️ Skip initializer if the DB isn't ready (for boot in k8s/CI)
unless BootGuard.model_ready?(:Organization)
  Rails.logger.warn "[TENANT] Skipping acts_as_tenant initializer — Database or Organization model not ready"
  return
end

# Configure acts_as_tenant for all environments with environment-specific settings
ActsAsTenant.configure do |config|
  # Test environment: Enable acts_as_tenant but don't require tenant for flexibility
  config.require_tenant = !Rails.env.test?
  config.pkey = :id
end

# Custom tenant logging and monitoring since ActsAsTenant 0.6 doesn't support hooks
module ActsAsTenant
  class << self
    alias_method :original_current_tenant=, :current_tenant=

    def current_tenant=(tenant)
      if tenant.present?
        if Rails.env.development?
          Rails.logger.debug "[TENANT] Changed to: #{tenant.id} - #{tenant.name} (#{tenant.subdomain})"
        elsif Rails.env.production?
          Rails.logger.info "[TENANT] #{tenant.id}"
          if tenant.respond_to?(:settings)
            Rails.cache.write("tenant:#{tenant.id}:info", {
              id: tenant.id,
              name: tenant.name,
              subdomain: tenant.subdomain,
              settings: tenant.settings
            }, expires_in: 1.hour)
          end
        end

        if defined?(RequestStore)
          RequestStore.store[:current_organization_id] = tenant.id
          RequestStore.store[:current_organization_name] = tenant.name
          RequestStore.store[:current_organization_subdomain] = tenant.subdomain
        end
      else
        Rails.logger.send(Rails.env.production? ? :warn : :debug, "[TENANT] Cleared tenant context")

        if defined?(RequestStore)
          RequestStore.store[:current_organization_id] = nil
          RequestStore.store[:current_organization_name] = nil
          RequestStore.store[:current_organization_subdomain] = nil
        end
      end

      self.original_current_tenant = tenant
    end
  end
end

# Production performance optimizations
if Rails.env.production?
  Rails.application.config.after_initialize do
    BootGuard.when_ready(:Organization) do
      Rails.application.config.organization_cache_ttl = 1.hour

      if defined?(Rails::Server)
        begin
          Organization.limit(100).find_each do |org|
            Rails.cache.write("org:subdomain:#{org.subdomain}", org.id, expires_in: 1.hour)
            Rails.cache.write("org:id:#{org.id}", org, expires_in: 1.hour)
          end
          Rails.logger.info "[TENANT] Preloaded #{Organization.count} organizations into cache"
        rescue => e
          Rails.logger.warn "[TENANT] Failed to preload organizations: #{e.message}"
        end
      end
    end
  end

  Organization.class_eval do
    def self.cached_find_by_subdomain(subdomain)
      return nil unless subdomain.present?
      cache_key = "org:subdomain:#{subdomain.downcase}"
      org_id = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        find_by(subdomain: subdomain.downcase)&.id
      end
      return nil unless org_id
      Rails.cache.fetch("org:id:#{org_id}", expires_in: 1.hour) { find(org_id) }
    end

    def self.invalidate_cache(organization)
      Rails.cache.delete("org:subdomain:#{organization.subdomain}")
      Rails.cache.delete("org:id:#{organization.id}")
      Rails.cache.delete("tenant:#{organization.id}:info")
    end
  end

  Organization.class_eval do
    after_update :invalidate_organization_cache
    after_destroy :invalidate_organization_cache

    private

    def invalidate_organization_cache
      Organization.invalidate_cache(self)
      Rails.logger.debug "[TENANT] Invalidated cache for organization #{id}"
    end
  end
end

# Development optimizations
if Rails.env.development?
  Rails.application.config.to_prepare do
    BootGuard.when_ready(:Organization) do
      Organization.connection.schema_cache.clear!
    end
  end
end

# Configure Sidekiq middleware for multi-tenancy
if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add Class.new do
        def call(worker, job, queue)
          organization_id = job['organization_id']
          if organization_id
            begin
              organization = if Rails.env.production?
                Organization.cached_find_by_subdomain(nil) || Organization.find(organization_id)
              else
                Organization.find(organization_id)
              end
              ActsAsTenant.with_tenant(organization) { yield }
            rescue ActiveRecord::RecordNotFound
              Rails.logger.error "[TENANT] Organization #{organization_id} not found for job #{job['class']}"
              yield
            end
          else
            ActsAsTenant.without_tenant { yield }
          end
        end
      end
    end
  end

  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add Class.new do
        def call(worker_class, job, queue, redis_pool)
          job['organization_id'] = ActsAsTenant.current_tenant&.id
          yield
        end
      end
    end
  end
end

# Production alerting for abnormal tenant clears
if Rails.env.production?
  Rails.application.config.after_initialize do
    tenant_clears_count = 0
    Module.new do
      def self.track_tenant_clear
        @tenant_clears_count = (@tenant_clears_count || 0) + 1
        if @tenant_clears_count > 10
          Rails.logger.error "[TENANT] ALERT: High number of tenant context clears (#{@tenant_clears_count})"
          @tenant_clears_count = 0
          Sentry.capture_message("High tenant context clears detected", level: :warning) if defined?(Sentry)
        end
      end
    end
  end
end

Rails.logger.info "[TENANT] Acts As Tenant configuration loaded for #{Rails.env} environment"
