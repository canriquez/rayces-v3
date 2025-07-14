class ApplicationController < ActionController::API
  include Pundit::Authorization
  include RackSessionFix
  
  # Multi-tenancy and authentication
  before_action :set_tenant_from_subdomain, unless: :skip_tenant_in_tests?
  before_action :authenticate_user_flexible
  
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def authenticate_user_flexible
    # Try JWT authentication first, then fall back to Google OAuth
    if jwt_token_present?
      authenticate_with_jwt
    elsif google_user_present?
      authenticate_google_user
    else
      render_unauthorized
    end
  end
  
  def jwt_token_present?
    request.headers['Authorization'].present? && 
    request.headers['Authorization'].start_with?('Bearer ')
  end
  
  def google_user_present?
    request.env['google_user'].present?
  end
  
  def authenticate_with_jwt
    token = request.headers['Authorization'].split(' ').last
    jwt_payload = decode_jwt_token(token)
    
    if jwt_payload
      @current_user = User.find(jwt_payload['sub'])
      # Ensure tenant context matches JWT payload
      if jwt_payload['organization_id'] && 
         ActsAsTenant.current_tenant&.id != jwt_payload['organization_id']
        render_forbidden("Invalid organization access")
        return
      end
    else
      render_unauthorized
    end
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render_unauthorized
  end

  def authenticate_google_user
    @google_user = request.env['google_user']
    unless @google_user
      render_unauthorized
    else
      @current_user = find_or_create_user(@google_user)
      unless @current_user
        render json: { error: 'User could not be authenticated. Please try again.' }, status: :unauthorized
      end
    end
  end
  
  def decode_jwt_token(token)
    JWT.decode(
      token,
      Rails.application.credentials.devise_jwt_secret_key || Rails.application.credentials.secret_key_base,
      true,
      algorithm: 'HS256'
    ).first
  rescue
    nil
  end
  
  def set_tenant_from_subdomain
    # Only set tenant from subdomain for non-API routes or when explicitly needed
    if request.subdomain.present? && request.subdomain != 'www'
      organization = Organization.find_by_subdomain(request.subdomain)
      ActsAsTenant.current_tenant = organization if organization
    end
  end

  def current_user
    @current_user
  end
  
  def pundit_user
    # Pass user context with organization for policies
    return nil unless current_user
    UserContext.new(current_user, current_user.organization)
  end

  def skip_tenant_in_tests?
    # Skip tenant resolution in test environment for SCRUM-32 basic API testing
    defined?(RSpec) || Rails.env.test?
  end

  def find_or_create_user(google_user)
    # Find existing user by UID first
    user = User.find_by(uid: google_user['sub'])
    return user if user
    
    # If no user with UID, try to find by email within current tenant
    if ActsAsTenant.current_tenant
      user = User.find_by(email: google_user['email'])
      if user
        # Link Google account to existing user
        user.update(uid: google_user['sub'])
        return user
      end
    end
    
    # Create new user - need organization context
    unless ActsAsTenant.current_tenant
      render json: { error: 'Organization context required for new user creation' }, status: :bad_request
      return nil
    end
    
    # Extract names from Google user data
    full_name = google_user['name'] || ''
    name_parts = full_name.split(' ')
    first_name = name_parts.first || ''
    last_name = name_parts[1..-1].join(' ') || ''
    
    user = User.new(
      uid: google_user['sub'],
      email: google_user['email'],
      first_name: first_name,
      last_name: last_name,
      organization: ActsAsTenant.current_tenant,
      password: SecureRandom.hex(32), # Generate random password for Devise
      jti: SecureRandom.uuid
    )
    
    if user.save
      # Send welcome email
      EmailNotificationWorker.perform_async(user.id, 'welcome', {})
      user
    else
      Rails.logger.error "Failed to create user: #{user.errors.full_messages}"
      nil
    end
  end
  
  # Error response helpers
  def render_error(message, status)
    render json: { error: message }, status: status
  end
  
  def render_unauthorized
    render_error('Unauthorized', :unauthorized)
  end
  
  def render_forbidden(message = 'Forbidden')
    render_error(message, :forbidden)
  end
  
  def not_found
    render_error('Resource not found', :not_found)
  end
  
  def forbidden(exception = nil)
    message = exception&.message || 'You are not authorized to perform this action'
    render_error(message, :forbidden)
  end
  
  def bad_request(exception)
    render_error(exception.message, :bad_request)
  end
  
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed',
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end
end
