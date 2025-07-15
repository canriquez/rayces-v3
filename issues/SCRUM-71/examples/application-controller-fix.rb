# Application Controller Fix for Authorization Issues
# This demonstrates how to fix common authorization and tenant issues

class ApplicationController < ActionController::API
  include Pundit::Authorization
  
  before_action :authenticate_user!
  before_action :set_tenant_context
  
  # Fix authorization callback issues
  after_action :verify_authorized, except: [:index, :options]
  after_action :verify_policy_scoped, only: [:index]
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from JWT::DecodeError, with: :invalid_token
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
      @current_user = User.find(decoded_token['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_unauthorized
    end
  end

  def current_user
    @current_user
  end

  def set_tenant_context
    return unless current_user

    organization = current_user.organization
    ActsAsTenant.current_tenant = organization
  end

  # Fix pundit_user method for UserContext
  def pundit_user
    return nil unless current_user
    
    organization = current_organization || current_user.organization
    UserContext.new(current_user, organization)
  end

  def current_organization
    @current_organization ||= ActsAsTenant.current_tenant || current_user&.organization
  end

  # Error handling methods
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    message = I18n.t("#{policy_name}.#{exception.query}", 
                    scope: "pundit", 
                    default: "You are not authorized to perform this action.")
    
    render json: { error: message }, status: :forbidden
  end

  def invalid_token
    render json: { error: 'Invalid or expired token' }, status: :unauthorized
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end

  def render_unauthorized
    render json: { error: 'Authentication required' }, status: :unauthorized
  end

  # Helper method for test environment
  def skip_authorization
    @_pundit_policy_authorized = true
  end

  def skip_policy_scope
    @_pundit_policy_scoped = true
  end
end