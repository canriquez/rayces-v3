# Example: Authentication Controllers for Devise JWT
# This example shows how to implement login/signup controllers

# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      
      skip_before_action :verify_authenticity_token
      before_action :configure_permitted_parameters, if: :devise_controller?

      def create
        resource = warden.authenticate!(auth_options)
        sign_in(resource_name, resource)
        
        render json: {
          message: 'Logged in successfully.',
          user: UserSerializer.new(resource).serializable_hash[:data][:attributes],
          token: request.env['warden-jwt_auth.token']
        }, status: :ok
      end

      def destroy
        if current_user
          # Revoke the JWT token
          current_user.update!(jti: SecureRandom.uuid)
          sign_out(current_user)
          render json: { message: 'Logged out successfully.' }, status: :ok
        else
          render json: { error: 'No active session' }, status: :unprocessable_entity
        end
      end

      private

      def respond_with(resource, _opts = {})
        render json: {
          message: 'Logged in successfully.',
          user: UserSerializer.new(resource).serializable_hash[:data][:attributes],
          token: request.env['warden-jwt_auth.token']
        }, status: :ok
      end

      def respond_to_on_destroy
        if current_user
          render json: { message: 'Logged out successfully.' }, status: :ok
        else
          render json: { error: 'No active session' }, status: :unprocessable_entity
        end
      end
    end
  end
end

# app/controllers/api/v1/registrations_controller.rb
module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json
      
      skip_before_action :verify_authenticity_token
      before_action :configure_permitted_parameters, if: :devise_controller?

      def create
        build_resource(sign_up_params)
        
        # Set organization from subdomain or params
        if request.subdomain.present?
          resource.organization = Organization.find_by(subdomain: request.subdomain)
        elsif params[:organization_id].present?
          resource.organization = Organization.find(params[:organization_id])
        end
        
        # Validate organization
        unless resource.organization&.active?
          return render json: {
            error: 'Invalid or inactive organization'
          }, status: :unprocessable_entity
        end
        
        resource.save
        yield resource if block_given?
        
        if resource.persisted?
          if resource.active_for_authentication?
            sign_up(resource_name, resource)
            render json: {
              message: 'Signed up successfully.',
              user: UserSerializer.new(resource).serializable_hash[:data][:attributes],
              token: request.env['warden-jwt_auth.token']
            }, status: :created
          else
            expire_data_after_sign_in!
            render json: {
              message: "A confirmation email has been sent to #{resource.email}",
              user: UserSerializer.new(resource).serializable_hash[:data][:attributes]
            }, status: :created
          end
        else
          clean_up_passwords resource
          render json: {
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :organization_id])
      end

      def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone)
      end
    end
  end
end

# app/controllers/api/v1/passwords_controller.rb
module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      respond_to :json
      
      skip_before_action :verify_authenticity_token

      def create
        self.resource = resource_class.send_reset_password_instructions(resource_params)
        yield resource if block_given?

        if successfully_sent?(resource)
          render json: {
            message: 'Reset password instructions have been sent to your email.'
          }, status: :ok
        else
          render json: {
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        self.resource = resource_class.reset_password_by_token(resource_params)
        yield resource if block_given?

        if resource.errors.empty?
          resource.unlock_access! if unlockable?(resource)
          render json: {
            message: 'Password has been reset successfully.'
          }, status: :ok
        else
          set_minimum_password_length
          render json: {
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end