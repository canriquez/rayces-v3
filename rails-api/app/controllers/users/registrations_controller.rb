# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  respond_to :json
  
  before_action :configure_sign_up_params, only: [:create]
  before_action :set_organization, only: [:create]

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Signed up successfully.' },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
        token: request.env['warden-jwt_auth.token']
      }, status: :ok
    else
      render json: {
        status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_entity
    end
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :role, :organization_id])
  end

  def set_organization
    # For subdomain-based tenant resolution
    if request.subdomain.present? && request.subdomain != 'www'
      @organization = Organization.find_by_subdomain(request.subdomain)
      params[:user][:organization_id] = @organization.id if @organization
    end
    
    # If no organization found or provided, return error
    unless params[:user][:organization_id].present?
      render json: { 
        status: { message: "Organization must be specified" }
      }, status: :unprocessable_entity
      return false
    end
  end
end