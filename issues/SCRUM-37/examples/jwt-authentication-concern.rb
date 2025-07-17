# Example: JWT Authentication Concern
# This example shows how to create a reusable concern for JWT authentication

# app/controllers/concerns/jwt_authenticatable.rb
module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_from_token!
  end

  private

  def authenticate_user_from_token!
    # Extract JWT token from Authorization header
    token = extract_jwt_token
    return render_unauthorized unless token
    
    begin
      # Decode the JWT token
      payload = JWT.decode(
        token,
        Rails.application.credentials.devise_jwt_secret_key!,
        true,
        { algorithm: 'HS256' }
      ).first
      
      # Find and set the organization (multi-tenancy)
      organization = Organization.find(payload['organization_id'])
      ActsAsTenant.current_tenant = organization
      
      # Find and set the current user
      @current_user = User.find(payload['sub'])
      
      # Verify the JTI hasn't been revoked
      if @current_user.jti != payload['jti']
        return render_unauthorized
      end
      
      # Optional: Check token expiration
      if payload['exp'] < Time.current.to_i
        return render_unauthorized
      end
      
    rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound => e
      Rails.logger.error "JWT Authentication Error: #{e.message}"
      render_unauthorized
    end
  end

  def extract_jwt_token
    header = request.headers['Authorization']
    header&.split(' ')&.last if header&.starts_with?('Bearer ')
  end

  def render_unauthorized
    render json: { 
      error: 'Unauthorized',
      message: 'Invalid or expired authentication token'
    }, status: :unauthorized
  end

  def current_user
    @current_user
  end

  def current_organization
    ActsAsTenant.current_tenant
  end
  
  def user_signed_in?
    current_user.present?
  end
  
  # Helper to require specific roles
  def require_role!(role)
    unless current_user&.has_role?(role)
      render json: {
        error: 'Forbidden',
        message: "This action requires #{role} role"
      }, status: :forbidden
    end
  end
  
  # Helper to require admin role
  def require_admin!
    require_role!('admin')
  end
  
  # Helper to require professional role
  def require_professional!
    require_role!('professional')
  end
end

# Usage example in a controller:
# class Api::V1::AppointmentsController < ApplicationController
#   include JwtAuthenticatable
#   
#   before_action :require_professional!, only: [:update_status]
#   
#   def index
#     # current_user and current_organization are available
#     @appointments = current_user.appointments
#   end
# end