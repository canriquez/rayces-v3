# app/controllers/api/v1/appointments_controller.rb
class Api::V1::AppointmentsController < Api::V1::BaseController
  before_action :set_appointment, only: [:show, :update, :destroy, :pre_confirm, :confirm, :execute, :cancel]
  
  def index
    begin
      @appointments = policy_scope(Appointment).includes(:professional, :client, :student)
    rescue => e
      Rails.logger.error "AppointmentsController#index error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "Internal server error: #{e.message}" }, status: :internal_server_error
      return
    end
    
    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @appointments = @appointments.where(scheduled_at: start_date.beginning_of_day..end_date.end_of_day)
    end
    
    # Filter by professional if provided
    if params[:professional_id].present?
      @appointments = @appointments.for_professional(params[:professional_id])
    end
    
    # Filter by state if provided
    if params[:state].present?
      @appointments = @appointments.where(state: params[:state])
    end
    
    @appointments = @appointments.order(:scheduled_at)
    
    # Return appointments in the expected format for tests
    render json: { 
      appointments: ActiveModelSerializers::SerializableResource.new(
        @appointments,
        each_serializer: AppointmentSerializer,
        scope: current_user
      ).as_json
    }
  end
  
  def show
    authorize @appointment
    render json: { appointment: ActiveModelSerializers::SerializableResource.new(
      @appointment,
      serializer: AppointmentSerializer,
      scope: current_user
    ).as_json }
  end
  
  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.organization = current_user.organization
    @appointment.client = current_user unless current_user.admin? || current_user.staff?
    
    authorize @appointment
    
    if @appointment.save
      render json: { appointment: ActiveModelSerializers::SerializableResource.new(
        @appointment,
        serializer: AppointmentSerializer,
        scope: current_user
      ).as_json }, status: :created
    else
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @appointment
    
    if @appointment.update(appointment_params)
      render json: { appointment: ActiveModelSerializers::SerializableResource.new(
        @appointment,
        serializer: AppointmentSerializer,
        scope: current_user
      ).as_json }
    else
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @appointment
    @appointment.destroy
    head :no_content
  end
  
  # State transitions
  def pre_confirm
    authorize @appointment, :pre_confirm?
    
    if @appointment.may_pre_confirm? && @appointment.pre_confirm!
      render json: { appointment: ActiveModelSerializers::SerializableResource.new(
        @appointment,
        serializer: AppointmentSerializer,
        scope: current_user
      ).as_json }
    else
      render json: { error: 'Cannot pre-confirm appointment' }, status: :unprocessable_entity
    end
  end
  
  def confirm
    authorize @appointment, :confirm?
    
    if @appointment.may_confirm? && @appointment.confirm!
      render json: { appointment: ActiveModelSerializers::SerializableResource.new(
        @appointment,
        serializer: AppointmentSerializer,
        scope: current_user
      ).as_json }
    else
      render json: { error: 'Cannot confirm appointment - invalid state transition' }, status: :unprocessable_entity
    end
  end
  
  def execute
    authorize @appointment, :execute?
    
    # Update notes if provided
    if params[:notes].present?
      @appointment.notes = params[:notes]
    end
    
    if @appointment.may_execute? && @appointment.execute!
      render json: { appointment: ActiveModelSerializers::SerializableResource.new(
        @appointment,
        serializer: AppointmentSerializer,
        scope: current_user
      ).as_json }
    else
      render json: { error: 'Cannot execute appointment' }, status: :unprocessable_entity
    end
  end
  
  def cancel
    authorize @appointment, :cancel?
    
    # Handle both cancellation_reason and notes params
    @appointment.cancellation_reason = params[:cancellation_reason] if params[:cancellation_reason].present?
    @appointment.notes = params[:notes] if params[:notes].present?
    
    if @appointment.may_cancel? && @appointment.cancel!(current_user)
      render json: { appointment: ActiveModelSerializers::SerializableResource.new(
        @appointment,
        serializer: AppointmentSerializer,
        scope: current_user
      ).as_json }
    else
      render json: { error: 'Cannot cancel appointment' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_appointment
    @appointment = Appointment.find(params[:id])
  end
  
  def appointment_params
    params.require(:appointment).permit(
      :professional_id, :client_id, :student_id,
      :scheduled_at, :duration_minutes,
      :notes, :price, :uses_credits, :credits_used
    )
  end
end