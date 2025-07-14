# app/controllers/api/v1/appointments_controller.rb
class Api::V1::AppointmentsController < Api::V1::BaseController
  before_action :set_appointment, only: [:show, :update, :destroy, :pre_confirm, :confirm, :execute, :cancel]
  
  def index
    @appointments = policy_scope(Appointment).includes(:professional, :client, :student)
    
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
    render_paginated(@appointments, AppointmentSerializer)
  end
  
  def show
    authorize @appointment
    render json: @appointment, serializer: AppointmentSerializer
  end
  
  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.organization = current_user.organization
    @appointment.client = current_user unless current_user.admin? || current_user.staff?
    
    authorize @appointment
    
    if @appointment.save
      render json: @appointment, serializer: AppointmentSerializer, status: :created
    else
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @appointment
    
    if @appointment.update(appointment_params)
      render json: @appointment, serializer: AppointmentSerializer
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
    
    if @appointment.pre_confirm!
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot pre-confirm appointment' }, status: :unprocessable_entity
    end
  end
  
  def confirm
    authorize @appointment, :confirm?
    
    if @appointment.confirm!
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot confirm appointment' }, status: :unprocessable_entity
    end
  end
  
  def execute
    authorize @appointment, :execute?
    
    if @appointment.execute!
      render json: @appointment, serializer: AppointmentSerializer
    else
      render json: { error: 'Cannot execute appointment' }, status: :unprocessable_entity
    end
  end
  
  def cancel
    authorize @appointment, :cancel?
    
    @appointment.cancellation_reason = params[:cancellation_reason]
    
    if @appointment.cancel!(current_user)
      render json: @appointment, serializer: AppointmentSerializer
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