# Appointments API Controller with Full CRUD and State Transitions
# This demonstrates proper Rails API controller with JWT authentication and Pundit authorization

class Api::V1::AppointmentsController < Api::V1::BaseController
  before_action :set_appointment, only: [:show, :update, :destroy, :pre_confirm, :confirm, :execute, :cancel]
  before_action :authenticate_user!
  
  # GET /api/v1/appointments
  def index
    @appointments = policy_scope(Appointment)
                      .includes(:professional, :student, :organization)
                      .page(params[:page])
                      .per(params[:per_page] || 25)
    
    @appointments = @appointments.where(state: params[:state]) if params[:state].present?
    @appointments = @appointments.where(professional_id: params[:professional_id]) if params[:professional_id].present?
    @appointments = @appointments.where('scheduled_at >= ?', params[:from_date]) if params[:from_date].present?
    @appointments = @appointments.where('scheduled_at <= ?', params[:to_date]) if params[:to_date].present?
    
    render json: @appointments, each_serializer: AppointmentSerializer
  end

  # GET /api/v1/appointments/1
  def show
    authorize @appointment
    render json: @appointment, serializer: AppointmentSerializer
  end

  # POST /api/v1/appointments
  def create
    @appointment = current_organization.appointments.build(appointment_params)
    @appointment.state = 'draft'
    
    authorize @appointment
    
    if @appointment.save
      # Schedule reminder worker
      AppointmentReminderWorker.perform_in(
        24.hours, 
        @appointment.id
      ) if @appointment.pre_confirmed?
      
      render json: @appointment, serializer: AppointmentSerializer, status: :created
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/appointments/1
  def update
    authorize @appointment
    
    if @appointment.update(appointment_params)
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { errors: @appointment.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/appointments/1
  def destroy
    authorize @appointment
    
    if @appointment.can_cancel?
      @appointment.cancel!
      
      # Issue credits if applicable
      if @appointment.credit_issued?
        CreditService.issue_credit(@appointment.student, @appointment.credit_amount)
      end
      
      head :no_content
    else
      render json: { error: 'Cannot cancel appointment' }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/appointments/1/pre_confirm
  def pre_confirm
    authorize @appointment, :update?
    
    if @appointment.can_pre_confirm?
      @appointment.pre_confirm!
      
      # Schedule expiration reminder
      AppointmentReminderWorker.perform_in(
        24.hours, 
        @appointment.id
      )
      
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot pre-confirm appointment' }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/appointments/1/confirm
  def confirm
    authorize @appointment, :update?
    
    if @appointment.can_confirm?
      @appointment.confirm!
      
      # Send confirmation email
      EmailNotificationWorker.perform_async(
        'appointment_confirmed',
        @appointment.id
      )
      
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot confirm appointment' }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/appointments/1/execute
  def execute
    authorize @appointment, :update?
    
    if @appointment.can_execute?
      @appointment.execute!
      
      # Send completion notification
      EmailNotificationWorker.perform_async(
        'appointment_completed',
        @appointment.id
      )
      
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot execute appointment' }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/appointments/1/cancel
  def cancel
    authorize @appointment, :update?
    
    if @appointment.can_cancel?
      @appointment.cancel!
      
      # Handle credit issuance based on cancellation timing
      if @appointment.eligible_for_credit?
        CreditService.issue_credit(@appointment.student, @appointment.credit_amount)
      end
      
      # Send cancellation notification
      EmailNotificationWorker.perform_async(
        'appointment_cancelled',
        @appointment.id
      )
      
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot cancel appointment' }, status: :unprocessable_entity
    end
  end

  private

  def set_appointment
    @appointment = current_organization.appointments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Appointment not found' }, status: :not_found
  end

  def appointment_params
    params.require(:appointment).permit(
      :professional_id,
      :student_id,
      :scheduled_at,
      :duration,
      :notes,
      :appointment_type,
      :priority
    )
  end
end