# Application Controller Multi-tenant Setup Example
# This example shows different approaches to setting up tenant context in Rails controllers
# Based on acts_as_tenant best practices and real-world implementations

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include Pundit::Authorization
  
  # acts_as_tenant configuration
  set_current_tenant_through_filter
  
  # Filters
  before_action :set_tenant
  before_action :authenticate_user!, except: [:health_check]
  before_action :set_locale
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index], unless: :skip_authorization?
  after_action :verify_policy_scoped, only: [:index], unless: :skip_authorization?
  
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :tenant_required
  
  private
  
  # Option 1: Set tenant by subdomain (most common for SaaS)
  def set_tenant
    # Extract subdomain from request
    subdomain = extract_subdomain_from_request
    
    if subdomain.present?
      organization = Organization.active.find_by(subdomain: subdomain)
      
      if organization
        ActsAsTenant.current_tenant = organization
      else
        render_error('Organization not found or inactive', :not_found)
      end
    elsif request.headers['X-Organization-Subdomain'].present?
      # Option 2: Set tenant from custom header (useful for API clients)
      set_tenant_from_header
    elsif current_user&.organization
      # Option 3: Set tenant from authenticated user
      ActsAsTenant.current_tenant = current_user.organization
    else
      # Option 4: Check if this is a public endpoint that doesn't require tenant
      unless public_endpoint?
        render_error('Organization context required', :bad_request)
      end
    end
  end
  
  # Alternative approach: Set tenant by domain or subdomain
  def set_tenant_by_domain_or_subdomain
    organization = Organization.find_by_domain_or_subdomain(request.host)
    
    if organization
      ActsAsTenant.current_tenant = organization
    else
      render_error('Organization not found', :not_found)
    end
  end
  
  # Set tenant from custom header
  def set_tenant_from_header
    subdomain = request.headers['X-Organization-Subdomain']
    organization = Organization.active.find_by(subdomain: subdomain)
    
    if organization
      # Verify user has access to this organization
      if current_user && !current_user.can_access_organization?(organization)
        render_error('Not authorized to access this organization', :forbidden)
        return
      end
      
      ActsAsTenant.current_tenant = organization
    else
      render_error('Invalid organization subdomain', :bad_request)
    end
  end
  
  # Extract subdomain from request
  def extract_subdomain_from_request
    # Handle different subdomain extraction strategies
    if Rails.env.production?
      # In production, use request.subdomain
      # This assumes your app is at *.yourdomain.com
      request.subdomain.presence
    else
      # In development/test, you might use lvh.me or custom logic
      # Example: org1.lvh.me:3000
      if request.host.include?('lvh.me')
        request.host.split('.').first
      else
        # Fallback to parameter for easy testing
        params[:subdomain] || request.subdomain
      end
    end
  end
  
  # Authenticate user (JWT example)
  def authenticate_user!
    token = extract_token_from_header
    return unauthorized unless token
    
    begin
      decoded_token = JWT.decode(
        token, 
        Rails.application.credentials.secret_key_base, 
        true, 
        { algorithm: 'HS256' }
      )
      
      user_id = decoded_token[0]['user_id']
      organization_id = decoded_token[0]['organization_id']
      
      @current_user = User.find(user_id)
      
      # Verify user belongs to the organization in the token
      unless @current_user.organization_id == organization_id
        return unauthorized
      end
      
      # Verify organization matches current tenant if set
      if ActsAsTenant.current_tenant && ActsAsTenant.current_tenant.id != organization_id
        return unauthorized
      end
      
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def current_organization
    ActsAsTenant.current_tenant
  end
  
  # Set locale based on organization or user preference
  def set_locale
    I18n.locale = if current_organization&.locale.present?
                    current_organization.locale
                  elsif current_user&.locale.present?
                    current_user.locale
                  elsif params[:locale].present?
                    params[:locale]
                  else
                    I18n.default_locale
                  end
  end
  
  # Helper methods
  def extract_token_from_header
    request.headers['Authorization']&.split(' ')&.last
  end
  
  def public_endpoint?
    # Define your public endpoints here
    controller_name == 'health' || 
    (controller_name == 'sessions' && action_name == 'create') ||
    (controller_name == 'registrations' && action_name == 'create')
  end
  
  def skip_authorization?
    public_endpoint? || devise_controller?
  end
  
  # Error responses
  def render_error(message, status)
    render json: { error: message }, status: status
  end
  
  def not_found
    render_error('Resource not found', :not_found)
  end
  
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed', 
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end
  
  def forbidden
    render_error('Not authorized', :forbidden)
  end
  
  def unauthorized
    render_error('Unauthorized', :unauthorized)
  end
  
  def tenant_required
    render_error('Organization context required', :bad_request)
  end
end

# Example of a controller that needs special tenant handling
class AdminController < ApplicationController
  # Allow admins to switch between organizations
  skip_before_action :set_tenant
  before_action :set_admin_tenant
  
  private
  
  def set_admin_tenant
    # Only super admins can switch organizations
    unless current_user&.super_admin?
      return forbidden
    end
    
    if params[:organization_id].present?
      organization = Organization.find(params[:organization_id])
      ActsAsTenant.current_tenant = organization
    else
      # Show all organizations for super admin
      ActsAsTenant.without_tenant do
        # Admin can see all data
      end
    end
  end
end

# Example of a public controller that doesn't require tenant
class PublicPagesController < ApplicationController
  skip_before_action :set_tenant
  skip_before_action :authenticate_user!
  
  def landing
    # Public landing page
    render json: { message: 'Welcome to Rayces' }
  end
  
  def pricing
    # Public pricing page
    render json: { plans: Organization::SUBSCRIPTION_PLANS }
  end
end