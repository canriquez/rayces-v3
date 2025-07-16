class ApplicationController < ActionController::API
  include Pundit::Authorization
  include RackSessionFix
  
  # Multi-tenancy and authentication
  before_action :authenticate_user_flexible
  before_action :resolve_tenant_context, unless: :skip_tenant_in_tests?
  before_action :validate_tenant_access, unless: :skip_tenant_in_tests?
  
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
    auth_header = request.headers['Authorization']
    auth_header.present? && auth_header.strip.present? && auth_header.start_with?('Bearer ')
  end
  
  def google_user_present?
    request.env['google_user'].present?
  end
  
  def authenticate_with_jwt
    auth_header = request.headers['Authorization']
    
    # Handle empty or missing authorization header
    if auth_header.blank? || auth_header.strip.blank? || !auth_header.include?(' ')
      render_unauthorized
      return
    end
    
    token = auth_header.split(' ').last
    jwt_payload = decode_jwt_token(token)
    
    if jwt_payload
      # CRITICAL: JWT payload uses 'user_id' not 'sub'
      user_id = jwt_payload['user_id']
      # Bypass tenant scoping for user lookup during authentication
      @current_user = ActsAsTenant.without_tenant { User.find(user_id) }
      
      # Store JWT organization for later validation in resolve_tenant_context
      @jwt_organization_id = jwt_payload['organization_id']
    else
      render_unauthorized
    end
  rescue JWT::DecodeError => e
    render_unauthorized
  rescue ActiveRecord::RecordNotFound => e
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
      jwt_secret_key,
      true,
      algorithm: 'HS256'
    ).first
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
  
  # Enhanced tenant resolution with multiple strategies
  def resolve_tenant_context
    tenant = resolve_tenant_from_strategies
    
    if tenant
      ActsAsTenant.current_tenant = tenant
      Rails.logger.debug "[TENANT] Resolved to: #{tenant.id} - #{tenant.name} (#{tenant.subdomain})"
    else
      Rails.logger.warn "[TENANT] Could not resolve tenant context"
      handle_missing_tenant unless allow_missing_tenant?
    end
  end
  
  def resolve_tenant_from_strategies
    # Strategy 1: Explicit organization header (for API calls)
    tenant = resolve_tenant_from_header
    return tenant if tenant
    
    # Strategy 2: Subdomain resolution (for web interface)
    tenant = resolve_tenant_from_subdomain  
    return tenant if tenant
    
    # Strategy 3: User's default organization (fallback for authenticated requests)
    tenant = resolve_tenant_from_user
    return tenant if tenant
    
    nil
  end
  
  def resolve_tenant_from_header
    org_header = request.headers['X-Organization-Id'] || request.headers['X-Organization-Subdomain']
    return nil unless org_header.present?
    
    if org_header.match?(/\A\d+\z/) # Numeric ID
      Organization.find_by(id: org_header)
    else # Subdomain
      Organization.find_by(subdomain: org_header)
    end
  end
  
  def resolve_tenant_from_subdomain
    return nil unless request.subdomain.present? && request.subdomain != 'www'
    Organization.find_by(subdomain: request.subdomain)
  end
  
  def resolve_tenant_from_user
    return nil unless current_user_from_token
    current_user_from_token.organization
  end
  
  def current_user_from_token
    return @current_user_from_token if defined?(@current_user_from_token)
    
    @current_user_from_token = if jwt_token_present?
      token = request.headers['Authorization'].split(' ').last
      jwt_payload = decode_jwt_token(token)
      # CRITICAL: JWT payload uses 'user_id' not 'sub'
      jwt_payload ? User.find_by(id: jwt_payload['user_id']) : nil
    else
      nil
    end
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    @current_user_from_token = nil
  end
  
  def validate_tenant_access
    return unless ActsAsTenant.current_tenant && current_user
    
    # Validate JWT organization matches resolved tenant
    if @jwt_organization_id && ActsAsTenant.current_tenant.id != @jwt_organization_id
      Rails.logger.warn "[JWT] Organization mismatch: JWT=#{@jwt_organization_id}, Current=#{ActsAsTenant.current_tenant.id}"
      render_forbidden("Invalid organization access")
      return
    end
    
    # Ensure user belongs to the resolved tenant
    unless current_user.can_access_organization?(ActsAsTenant.current_tenant)
      Rails.logger.warn "[TENANT] Access denied: User #{current_user.id} cannot access organization #{ActsAsTenant.current_tenant.id}"
      render_forbidden("You don't have access to this organization")
    end
  end
  
  def handle_missing_tenant
    if api_endpoint?
      render_error('Organization context required. Please specify X-Organization-Id or X-Organization-Subdomain header.', :bad_request)
    else
      render_error('Organization not found. Please check the subdomain.', :not_found)
    end
  end
  
  def allow_missing_tenant?
    # Allow missing tenant for certain endpoints that don't require organization context
    devise_controller? || 
    (controller_name == 'health' && action_name == 'check') ||
    (controller_name == 'organizations' && action_name == 'index')
  end
  
  def api_endpoint?
    request.path.start_with?('/api/')
  end

  def current_user
    @current_user
  end
  
  def pundit_user
    # Pass user context with organization for policies
    return nil unless current_user
    # CRITICAL: Must return UserContext with current organization context
    organization = current_organization || current_user.organization
    UserContext.new(current_user, organization)
  end
  
  def current_organization
    @current_organization ||= ActsAsTenant.current_tenant || current_user&.organization
  end

  def skip_tenant_in_tests?
    # Only skip tenant resolution for specific test scenarios, not all tests
    # This allows proper tenant context setup in authorization and multi-tenant tests
    return false unless Rails.env.test?
    
    # Skip for specific controller/action combinations that don't need tenant context
    (controller_name == 'health' && action_name == 'check') ||
    (controller_name == 'users' && action_name == 'sign_in') ||
    request.path.match?(/\/oauth\//)
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
  
  def jwt_secret_key
    Rails.application.credentials.devise_jwt_secret_key || 
    Rails.application.credentials.secret_key_base || 
    ENV['SECRET_KEY_BASE']
  end
end
