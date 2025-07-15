# API Controller Authorization Example
# Shows how to implement authorization in Rails API controllers

# Base controller with Pundit integration
class Api::V1::BaseController < ApplicationController
  include Pundit::Authorization
  
  # Ensure authorization is always performed
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  
  # Handle authorization errors with proper HTTP status
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  # Set tenant context before any action
  before_action :set_tenant_context
  
  private
  
  def user_not_authorized(exception)
    # Log the authorization failure for security auditing
    Rails.logger.warn(
      "Authorization denied: User #{current_user&.id} attempted #{request.method} " \
      "#{request.path} - Policy: #{exception.policy.class}, Query: #{exception.query}"
    )
    
    # Return 403 Forbidden (not 401 Unauthorized)
    render json: { 
      error: 'You are not authorized to perform this action',
      code: 'FORBIDDEN'
    }, status: :forbidden
  end
  
  def set_tenant_context
    # Ensure tenant context is set from JWT or subdomain
    if current_user
      ActsAsTenant.current_tenant = current_user.organization
    elsif request.headers['X-Organization-ID'].present?
      # Fallback to header-based tenant detection
      org = Organization.find_by(id: request.headers['X-Organization-ID'])
      ActsAsTenant.current_tenant = org if org
    end
    
    # Verify tenant context is set
    unless ActsAsTenant.current_tenant
      render json: { 
        error: 'Tenant context required',
        code: 'TENANT_REQUIRED' 
      }, status: :unprocessable_entity
    end
  end
  
  # Override pundit_user to support custom context
  def pundit_user
    UserContext.new(current_user, request)
  end
end

# Organizations controller with authorization
class Api::V1::OrganizationsController < Api::V1::BaseController
  before_action :set_organization, only: [:show, :update, :destroy]
  
  def index
    # Policy scope ensures users only see authorized organizations
    @organizations = policy_scope(Organization)
    render json: @organizations, each_serializer: OrganizationSerializer
  end
  
  def show
    # Authorize the specific organization
    authorize @organization
    render json: @organization, serializer: OrganizationSerializer
  end
  
  def create
    @organization = Organization.new(organization_params)
    authorize @organization
    
    if @organization.save
      render json: @organization, status: :created
    else
      render json: { errors: @organization.errors }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @organization
    
    if @organization.update(organization_params)
      render json: @organization
    else
      render json: { errors: @organization.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @organization
    @organization.destroy
    head :no_content
  end
  
  private
  
  def set_organization
    @organization = Organization.find(params[:id])
  end
  
  def organization_params
    # Use Pundit's permitted attributes if defined
    if policy(@organization).respond_to?(:permitted_attributes)
      params.require(:organization).permit(policy(@organization).permitted_attributes)
    else
      params.require(:organization).permit(:name, :subdomain, :settings)
    end
  end
end

# Users controller with role-based authorization
class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]
  
  def index
    @users = policy_scope(User).includes(:roles, :organization)
    
    # Apply additional filters while maintaining authorization
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.page(params[:page]).per(params[:per_page] || 25)
    
    render json: @users, each_serializer: UserSerializer
  end
  
  def show
    authorize @user
    render json: @user, serializer: UserSerializer, include: [:roles, :appointments]
  end
  
  def create
    @user = User.new(user_params)
    @user.organization = current_organization
    authorize @user
    
    if @user.save
      # Assign default role based on invitation type
      assign_initial_role(@user)
      render json: @user, status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @user
    
    # Use different permitted attributes based on who's updating
    permitted_params = if policy(@user).admin_update?
      admin_user_params
    else
      user_params
    end
    
    if @user.update(permitted_params)
      render json: @user
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @user
    @user.destroy
    head :no_content
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:email, :name, :phone, :avatar)
  end
  
  def admin_user_params
    params.require(:user).permit(:email, :name, :phone, :avatar, :active, role_ids: [])
  end
  
  def assign_initial_role(user)
    role_name = params.dig(:user, :initial_role) || 'client'
    role = Role.find_by(name: role_name, organization: user.organization)
    user.roles << role if role
  end
end

# Appointments controller with state-based authorization
class Api::V1::AppointmentsController < Api::V1::BaseController
  before_action :set_appointment, only: [:show, :update, :destroy, :pre_confirm, :confirm, :execute, :cancel]
  
  def index
    @appointments = policy_scope(Appointment)
      .includes(:professional, :student, :client)
      .order(scheduled_at: :desc)
    
    # Apply filters
    filter_appointments
    
    render json: @appointments, each_serializer: AppointmentSerializer
  end
  
  def show
    authorize @appointment
    render json: @appointment, serializer: AppointmentSerializer, include: [:professional, :student]
  end
  
  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.organization = current_organization
    @appointment.created_by = current_user
    
    authorize @appointment
    
    if @appointment.save
      render json: @appointment, status: :created
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @appointment
    
    if @appointment.update(appointment_params)
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @appointment
    @appointment.destroy
    head :no_content
  end
  
  # State transition endpoints
  def pre_confirm
    authorize @appointment, :pre_confirm?
    
    if @appointment.pre_confirm!
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def confirm
    authorize @appointment, :confirm?
    
    if @appointment.confirm!
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def execute
    authorize @appointment, :execute?
    
    @appointment.notes = params[:notes] if params[:notes].present?
    
    if @appointment.execute!
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  def cancel
    authorize @appointment, :cancel?
    
    @appointment.cancellation_reason = params[:reason]
    @appointment.cancelled_by = current_user
    
    if @appointment.cancel!
      render json: @appointment
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_appointment
    @appointment = Appointment.find(params[:id])
  end
  
  def appointment_params
    # Different permitted params based on user role
    base_params = [:scheduled_at, :duration_minutes, :appointment_type, :notes]
    
    if policy(Appointment).admin_create?
      params.require(:appointment).permit(base_params + [:professional_id, :student_id, :client_id, :price])
    elsif policy(Appointment).secretary_create?
      params.require(:appointment).permit(base_params + [:professional_id, :student_id, :client_id])
    else
      params.require(:appointment).permit(base_params + [:student_id])
    end
  end
  
  def filter_appointments
    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @appointments = @appointments.where(
        scheduled_at: params[:start_date]..params[:end_date]
      )
    end
    
    # State filter
    if params[:state].present?
      @appointments = @appointments.where(state: params[:state])
    end
    
    # Professional filter (respecting authorization)
    if params[:professional_id].present? && policy(Appointment).can_filter_by_professional?
      @appointments = @appointments.where(professional_id: params[:professional_id])
    end
    
    # Pagination
    @appointments = @appointments.page(params[:page]).per(params[:per_page] || 25)
  end
end

# Custom user context for additional authorization data
class UserContext
  attr_reader :user, :request

  def initialize(user, request)
    @user = user
    @request = request
  end
  
  # Delegate user methods
  def method_missing(method, *args, &block)
    user.send(method, *args, &block)
  end
  
  def respond_to_missing?(method, include_private = false)
    user.respond_to?(method, include_private)
  end
  
  # Additional context methods
  def ip_address
    request.remote_ip
  end
  
  def user_agent
    request.user_agent
  end
  
  def api_version
    request.headers['X-API-Version'] || 'v1'
  end
end