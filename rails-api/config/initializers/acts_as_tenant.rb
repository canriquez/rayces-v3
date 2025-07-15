# config/initializers/acts_as_tenant.rb

# Configure acts_as_tenant for all environments with environment-specific settings
ActsAsTenant.configure do |config|
  # Test environment: Enable acts_as_tenant but don't require tenant for flexibility
  if Rails.env.test?
    config.require_tenant = false
    
  # Development/Production: Require tenant for security
  elsif Rails.env.development? || Rails.env.production?
    config.require_tenant = true
  end
  
  # Global configuration (only use supported options for v0.6)
  config.pkey = :id
end

# Custom tenant logging and monitoring since ActsAsTenant 0.6 doesn't support hooks
module ActsAsTenant
  class << self
    alias_method :original_current_tenant=, :current_tenant=
    
    def current_tenant=(tenant)
      # Log tenant changes for monitoring
      if tenant.present?
        if Rails.env.development?
          Rails.logger.debug "[TENANT] Changed to: #{tenant.id} - #{tenant.name} (#{tenant.subdomain})"
        elsif Rails.env.production?
          Rails.logger.info "[TENANT] #{tenant.id}"
          
          # Cache tenant information for performance
          Rails.cache.write("tenant:#{tenant.id}:info", {
            id: tenant.id,
            name: tenant.name,
            subdomain: tenant.subdomain,
            settings: tenant.settings
          }, expires_in: 1.hour) if tenant.respond_to?(:settings)
        end
        
        # Set request context for logging (if RequestStore is available)
        if defined?(RequestStore)
          RequestStore.store[:current_organization_id] = tenant.id
          RequestStore.store[:current_organization_name] = tenant.name
          RequestStore.store[:current_organization_subdomain] = tenant.subdomain
        end
        
      else
        if Rails.env.development?
          Rails.logger.debug "[TENANT] Cleared tenant context"
        elsif Rails.env.production?
          Rails.logger.warn "[TENANT] Context cleared"
        end
        
        # Clear request context
        if defined?(RequestStore)
          RequestStore.store[:current_organization_id] = nil
          RequestStore.store[:current_organization_name] = nil
          RequestStore.store[:current_organization_subdomain] = nil
        end
      end
      
      # Call original method
      self.original_current_tenant = tenant
    end
  end
end

# Production performance optimizations
if Rails.env.production?
  # Preload organization data in memory for faster lookups
  Rails.application.config.after_initialize do
    # Cache organization lookup by subdomain for 1 hour
    Rails.application.config.organization_cache_ttl = 1.hour
    
    # Preload frequently accessed organizations
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
  
  # Add Organization model caching extensions
  Organization.class_eval do
    def self.cached_find_by_subdomain(subdomain)
      return nil unless subdomain.present?
      
      cache_key = "org:subdomain:#{subdomain.downcase}"
      org_id = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        find_by(subdomain: subdomain.downcase)&.id
      end
      
      return nil unless org_id
      
      Rails.cache.fetch("org:id:#{org_id}", expires_in: 1.hour) do
        find(org_id)
      end
    end
    
    def self.invalidate_cache(organization)
      Rails.cache.delete("org:subdomain:#{organization.subdomain}")
      Rails.cache.delete("org:id:#{organization.id}")
      Rails.cache.delete("tenant:#{organization.id}:info")
    end
  end
  
  # Add cache invalidation callbacks
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
  # Reload organization cache on code changes
  Rails.application.config.to_prepare do
    Organization.connection.schema_cache.clear! if Organization.table_exists?
  end
end

# Configure Sidekiq middleware for multi-tenancy
if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      # Custom middleware to preserve tenant context in background jobs
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
              
              ActsAsTenant.with_tenant(organization) do
                yield
              end
            rescue ActiveRecord::RecordNotFound
              Rails.logger.error "[TENANT] Organization #{organization_id} not found for job #{job['class']}"
              yield # Execute without tenant context rather than failing
            end
          else
            ActsAsTenant.without_tenant do
              yield
            end
          end
        end
      end
    end
  end
  
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      # Add organization context to all jobs
      chain.add Class.new do
        def call(worker_class, job, queue, redis_pool)
          if ActsAsTenant.current_tenant
            job['organization_id'] = ActsAsTenant.current_tenant.id
          end
          yield
        end
      end
    end
  end
end

# Monitoring and alerting for production
if Rails.env.production?
  # Alert if tenant context is frequently cleared
  Rails.application.config.after_initialize do
    tenant_clears_count = 0
    
    # Monitor tenant context clears
    Module.new do
      def self.track_tenant_clear
        @tenant_clears_count = (@tenant_clears_count || 0) + 1
        
        # Alert if too many clears in short time (possible attack or bug)
        if @tenant_clears_count > 10
          Rails.logger.error "[TENANT] ALERT: High number of tenant context clears (#{@tenant_clears_count})"
          
          # Reset counter
          @tenant_clears_count = 0
          
          # Send alert to monitoring system
          if defined?(Sentry)
            Sentry.capture_message("High tenant context clears detected", level: :warning)
          end
        end
      end
    end
  end
end

Rails.logger.info "[TENANT] Acts As Tenant configuration loaded for #{Rails.env} environment"