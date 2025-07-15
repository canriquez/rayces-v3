# Security Patterns for Multi-tenant Authorization
# Best practices and security considerations

# 1. Tenant Context Enforcement
module TenantScoped
  extend ActiveSupport::Concern
  
  included do
    before_action :ensure_tenant_context
    before_action :validate_tenant_consistency
  end
  
  private
  
  def ensure_tenant_context
    unless ActsAsTenant.current_tenant
      render json: { 
        error: 'Tenant context required',
        code: 'TENANT_REQUIRED' 
      }, status: :unprocessable_entity
    end
  end
  
  def validate_tenant_consistency
    # Ensure user belongs to the current tenant
    if current_user && current_user.organization_id != ActsAsTenant.current_tenant&.id
      Rails.logger.error(
        "Tenant mismatch: User #{current_user.id} (org: #{current_user.organization_id}) " \
        "accessing tenant #{ActsAsTenant.current_tenant&.id}"
      )
      
      render json: { 
        error: 'Tenant context mismatch',
        code: 'TENANT_MISMATCH' 
      }, status: :forbidden
    end
  end
end

# 2. Audit Trail for Authorization Events
module AuthorizationAuditing
  extend ActiveSupport::Concern
  
  included do
    after_action :log_authorization_event
  end
  
  private
  
  def log_authorization_event
    # Log successful authorizations for sensitive actions
    if response.successful? && sensitive_action?
      AuthorizationLog.create!(
        user_id: current_user&.id,
        organization_id: ActsAsTenant.current_tenant&.id,
        controller: controller_name,
        action: action_name,
        resource_type: @authorized_resource&.class&.name,
        resource_id: @authorized_resource&.id,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        performed_at: Time.current
      )
    end
    
    # Log authorization failures
    if response.status == 403
      SecurityEvent.create!(
        event_type: 'authorization_denied',
        user_id: current_user&.id,
        organization_id: ActsAsTenant.current_tenant&.id,
        details: {
          controller: controller_name,
          action: action_name,
          path: request.path,
          method: request.method,
          ip_address: request.remote_ip
        },
        occurred_at: Time.current
      )
    end
  end
  
  def sensitive_action?
    # Define which actions should be audited
    sensitive_actions = {
      'users' => ['create', 'update', 'destroy'],
      'organizations' => ['update', 'destroy'],
      'appointments' => ['execute', 'cancel'],
      'payments' => ['create', 'refund']
    }
    
    sensitive_actions[controller_name]&.include?(action_name)
  end
  
  # Track which resource was authorized
  def authorize(record, query = nil)
    @authorized_resource = record
    super
  end
end

# 3. Rate Limiting for Authorization Failures
class AuthorizationRateLimiter
  WINDOW_SIZE = 5.minutes
  MAX_FAILURES = 10
  
  def self.check(user_id, ip_address)
    key = "auth_failures:#{user_id || 'anonymous'}:#{ip_address}"
    
    failures = Rails.cache.read(key) || 0
    
    if failures >= MAX_FAILURES
      raise AuthorizationRateLimitExceeded, "Too many authorization failures"
    end
  end
  
  def self.record_failure(user_id, ip_address)
    key = "auth_failures:#{user_id || 'anonymous'}:#{ip_address}"
    
    Rails.cache.increment(key, 1, expires_in: WINDOW_SIZE)
  end
  
  class AuthorizationRateLimitExceeded < StandardError; end
end

# 4. Policy Testing for Security Vulnerabilities
module PolicySecurityTesting
  # Helper to test cross-tenant access attempts
  def test_cross_tenant_access(user, resource_class)
    other_org = create(:organization)
    other_resource = create(resource_class.name.underscore.to_sym, organization: other_org)
    
    policy = "#{resource_class}Policy".constantize.new(user, other_resource)
    
    # Test all standard actions
    [:index?, :show?, :create?, :update?, :destroy?].each do |action|
      if policy.respond_to?(action)
        expect(policy.send(action)).to be false, 
          "#{user.role} should not #{action} resources from other organizations"
      end
    end
  end
  
  # Helper to test privilege escalation attempts
  def test_privilege_escalation(lower_role_user, higher_role_user)
    policy = UserPolicy.new(lower_role_user, higher_role_user)
    
    expect(policy.update?).to be false,
      "#{lower_role_user.role} should not be able to modify #{higher_role_user.role}"
    
    expect(policy.destroy?).to be false,
      "#{lower_role_user.role} should not be able to delete #{higher_role_user.role}"
  end
  
  # Helper to test scope isolation
  def test_scope_isolation(user, resource_class)
    # Create resources in multiple organizations
    own_resources = create_list(resource_class.name.underscore.to_sym, 3, 
                                organization: user.organization)
    other_resources = create_list(resource_class.name.underscore.to_sym, 2, 
                                  organization: create(:organization))
    
    scope = "#{resource_class}Policy::Scope".constantize.new(user, resource_class).resolve
    
    expect(scope).to match_array(own_resources)
    expect(scope).not_to include(*other_resources)
  end
end

# 5. Secure Parameter Filtering
module SecureParameterFiltering
  extend ActiveSupport::Concern
  
  # Prevent users from setting organization_id or other sensitive fields
  def secure_params(model_name, allowed_params)
    # Get raw params
    raw_params = params.require(model_name).permit(*allowed_params)
    
    # Remove any attempt to set organization_id
    raw_params.delete(:organization_id)
    raw_params.delete(:created_by_id)
    
    # Remove role assignments unless admin
    unless current_user&.enhanced_admin?
      raw_params.delete(:role_ids)
      raw_params.delete(:roles)
      raw_params.delete(:admin)
    end
    
    # Log suspicious parameter attempts
    log_suspicious_params(params[model_name], allowed_params)
    
    raw_params
  end
  
  private
  
  def log_suspicious_params(submitted_params, allowed_params)
    return unless submitted_params.is_a?(ActionController::Parameters)
    
    suspicious = submitted_params.keys - allowed_params.map(&:to_s)
    suspicious_protected = suspicious & %w[organization_id created_by_id user_id admin]
    
    if suspicious_protected.any?
      Rails.logger.warn(
        "Suspicious parameters detected: User #{current_user&.id} attempted to set " \
        "#{suspicious_protected.join(', ')} for #{controller_name}##{action_name}"
      )
      
      SecurityEvent.create!(
        event_type: 'suspicious_parameters',
        user_id: current_user&.id,
        details: {
          attempted_params: suspicious_protected,
          controller: controller_name,
          action: action_name
        }
      )
    end
  end
end

# 6. Enhanced Application Controller with Security
class ApplicationController < ActionController::API
  include Pundit::Authorization
  include TenantScoped
  include AuthorizationAuditing
  include SecureParameterFiltering
  
  # Ensure authorization happens
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  
  # Handle various security exceptions
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from AuthorizationRateLimiter::AuthorizationRateLimitExceeded, with: :rate_limit_exceeded
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  
  private
  
  def user_not_authorized(exception)
    # Rate limit authorization failures
    AuthorizationRateLimiter.record_failure(current_user&.id, request.remote_ip)
    
    # Log the failure with context
    Rails.logger.warn(
      "[AUTHORIZATION DENIED] User: #{current_user&.id}, " \
      "Policy: #{exception.policy.class}, Query: #{exception.query}, " \
      "Record: #{exception.record.class}##{exception.record.id rescue 'N/A'}, " \
      "IP: #{request.remote_ip}, Path: #{request.path}"
    )
    
    render json: { 
      error: 'You are not authorized to perform this action',
      code: 'FORBIDDEN'
    }, status: :forbidden
  end
  
  def rate_limit_exceeded
    render json: { 
      error: 'Too many failed authorization attempts. Please try again later.',
      code: 'RATE_LIMITED'
    }, status: :too_many_requests
  end
  
  def record_not_found
    # Don't reveal if record exists in another tenant
    render json: { 
      error: 'Resource not found',
      code: 'NOT_FOUND'
    }, status: :not_found
  end
  
  # Override to add rate limiting check
  def authorize(record, query = nil)
    AuthorizationRateLimiter.check(current_user&.id, request.remote_ip)
    super
  end
end

# 7. Database-level Security with Row Level Security (RLS)
# This would be implemented at the database level, but here's the concept:
class EnableRowLevelSecurity < ActiveRecord::Migration[7.0]
  def up
    # Enable RLS on sensitive tables
    execute <<-SQL
      -- Enable Row Level Security
      ALTER TABLE users ENABLE ROW LEVEL SECURITY;
      ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
      ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
      
      -- Create policies for users table
      CREATE POLICY tenant_isolation ON users
        FOR ALL
        TO application_role
        USING (organization_id = current_setting('app.current_organization_id')::INTEGER);
      
      -- Create policies for appointments table  
      CREATE POLICY tenant_isolation ON appointments
        FOR ALL
        TO application_role
        USING (organization_id = current_setting('app.current_organization_id')::INTEGER);
    SQL
  end
  
  def down
    execute <<-SQL
      ALTER TABLE users DISABLE ROW LEVEL SECURITY;
      ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;
      ALTER TABLE organizations DISABLE ROW LEVEL SECURITY;
    SQL
  end
end