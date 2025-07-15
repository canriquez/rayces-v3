# acts_as_tenant Configuration Examples
# This file shows various configuration options and best practices for acts_as_tenant
# Based on the gem documentation and real-world implementations

# config/initializers/acts_as_tenant.rb
ActsAsTenant.configure do |config|
  # Option 1: Basic configuration with tenant requirement
  # This ensures all queries are tenant-scoped
  config.require_tenant = true
  
  # Option 2: Dynamic tenant requirement based on request
  # Useful when you have both tenant-scoped and global endpoints
  config.require_tenant = lambda do
    # Skip tenant requirement for specific paths
    if defined?($request) && $request.present?
      # Allow admin routes to work without tenant
      return false if $request.path.start_with?('/admin/')
      return false if $request.path.start_with?('/api/v1/public/')
      return false if $request.path == '/health'
    end
    
    # Require tenant for all other requests
    true
  end
  
  # Option 3: Custom tenant loading for background jobs
  # Useful when using soft delete or custom tenant lookup
  config.job_scope = lambda do
    # Include soft-deleted organizations in background jobs
    # This ensures jobs can complete even if org is deactivated
    unscoped.where(active: [true, false])
  end
  
  # Option 4: Tenant change hook for advanced features
  # Useful for Postgres Row Level Security or audit logging
  config.tenant_change_hook = lambda do |tenant|
    if tenant.present?
      # Set Postgres session variable for RLS
      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array(
            ["SET SESSION app.current_tenant_id = ?;", tenant.id]
          )
        )
      end
      
      # Log tenant changes for audit trail
      Rails.logger.info "[TENANT] Changed to: #{tenant.id} - #{tenant.name}"
      
      # Set additional context for error tracking
      if defined?(Sentry)
        Sentry.set_context('organization', {
          id: tenant.id,
          name: tenant.name,
          subdomain: tenant.subdomain
        })
      end
      
      # Update request context for logging
      if defined?(RequestStore)
        RequestStore.store[:current_organization_id] = tenant.id
        RequestStore.store[:current_organization_name] = tenant.name
      end
    else
      # Clear tenant context
      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        ActiveRecord::Base.connection.execute("RESET app.current_tenant_id;")
      end
      
      Rails.logger.info "[TENANT] Cleared tenant context"
    end
  end
  
  # Custom configuration for primary and foreign keys
  # Not typically needed unless using non-standard naming
  config.pkey = :id # Default
  config.default_fkey = :organization_id # Instead of account_id
  
  # Set default tenant method names
  config.current_tenant_method = :current_tenant
  config.tenant= :current_tenant=
end

# Development-specific configuration
# config/environments/development.rb
Rails.application.configure do
  # Set default tenant in development for better DX
  if defined?(Rails::Console)
    config.after_initialize do
      puts "=> Setting default tenant for development console"
      if Organization.exists?
        ActsAsTenant.current_tenant = Organization.first
        puts "=> ActsAsTenant.current_tenant = #{ActsAsTenant.current_tenant.name}"
      else
        puts "=> No organizations found. Run `rails db:seed` to create one."
      end
    end
    
    # Reset tenant after console reload
    ActiveSupport::Reloader.to_complete do
      if ActsAsTenant.current_tenant.nil? && Organization.exists?
        ActsAsTenant.current_tenant = Organization.first
        puts "=> Restored tenant: #{ActsAsTenant.current_tenant.name}"
      end
    end
  end
end

# Test environment configuration
# config/environments/test.rb
Rails.application.configure do
  # Use test tenant middleware for proper request spec handling
  require_dependency 'acts_as_tenant/test_tenant_middleware'
  config.middleware.use ActsAsTenant::TestTenantMiddleware
  
  # More lenient configuration for testing
  ActsAsTenant.configure do |config|
    config.require_tenant = false # Allow tests to run without tenant
  end
end

# Sidekiq configuration for background jobs
# config/initializers/sidekiq.rb
if defined?(Sidekiq)
  require 'acts_as_tenant/sidekiq'
  
  # Configure Sidekiq to maintain tenant context
  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add ActsAsTenant::Sidekiq::Server
    end
  end
  
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add ActsAsTenant::Sidekiq::Client
    end
  end
end

# ActiveJob configuration
# config/application.rb
class Application < Rails::Application
  # Ensure tenant context is preserved in jobs
  config.active_job.queue_adapter = :sidekiq
  
  # Custom job base class with tenant support
  config.active_job.default_job_class = 'TenantAwareJob'
end

# app/jobs/tenant_aware_job.rb
class TenantAwareJob < ApplicationJob
  # Automatically set tenant context for all jobs
  around_perform do |job, block|
    # The tenant_id is automatically stored by acts_as_tenant
    if job.arguments.last.is_a?(Hash) && job.arguments.last[:tenant_id]
      tenant = Organization.find(job.arguments.last[:tenant_id])
      ActsAsTenant.with_tenant(tenant) do
        block.call
      end
    else
      # Job was enqueued without tenant context
      Rails.logger.warn "Job #{job.class} executed without tenant context"
      block.call
    end
  end
end

# Request store configuration for thread-safe tenant storage
# Gemfile
gem 'request_store'

# config/application.rb
class Application < Rails::Application
  # Enable request store for thread-safe storage
  config.middleware.insert_after ActionDispatch::RequestId, RequestStore::Middleware
end

# Pundit integration for tenant-aware authorization
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record
  
  def initialize(user, record)
    @user = user
    @record = record
  end
  
  # Ensure all queries are tenant-scoped
  class Scope
    attr_reader :user, :scope
    
    def initialize(user, scope)
      @user = user
      @scope = scope
    end
    
    def resolve
      # ActsAsTenant automatically scopes queries
      # but we can add additional filters
      if user.has_role?('admin')
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
  
  protected
  
  # Helper to check if record belongs to current tenant
  def same_tenant?
    return true unless record.respond_to?(:organization)
    record.organization == ActsAsTenant.current_tenant
  end
end

# Custom validators for tenant-scoped uniqueness
# app/validators/tenant_uniqueness_validator.rb
class TenantUniquenessValidator < ActiveModel::Validator
  def validate(record)
    return unless ActsAsTenant.current_tenant
    
    # Example: Validate uniqueness of slug within tenant
    if record.class.where.not(id: record.id)
                   .where(slug: record.slug)
                   .exists?
      record.errors.add(:slug, 'has already been taken in this organization')
    end
  end
end

# Usage in model
class Service < ApplicationRecord
  acts_as_tenant :organization
  validates_with TenantUniquenessValidator
end

# Database setup with tenant isolation
# db/migrate/add_tenant_isolation_indexes.rb
class AddTenantIsolationIndexes < ActiveRecord::Migration[7.0]
  def change
    # Add composite indexes for better performance
    # Always include organization_id as the first column
    add_index :users, [:organization_id, :email], unique: true
    add_index :users, [:organization_id, :created_at]
    add_index :users, [:organization_id, :active]
    
    add_index :appointments, [:organization_id, :start_time]
    add_index :appointments, [:organization_id, :professional_profile_id, :start_time], 
              name: 'idx_appointments_org_prof_time'
    add_index :appointments, [:organization_id, :client_profile_id]
    add_index :appointments, [:organization_id, :status]
    
    add_index :posts, [:organization_id, :created_at]
    add_index :posts, [:organization_id, :user_id]
    
    # Ensure foreign keys include organization_id
    add_foreign_key :users, :organizations
    add_foreign_key :appointments, :organizations
    add_foreign_key :posts, :organizations
  end
end