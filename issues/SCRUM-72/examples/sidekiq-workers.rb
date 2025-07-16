# Sidekiq Background Workers with Multi-Tenant Support
# This demonstrates proper Sidekiq worker implementation with tenant context preservation

# Base Application Worker with tenant context
class ApplicationWorker
  include Sidekiq::Worker
  
  # Preserve tenant context across jobs
  def perform(*args)
    tenant_id = args.first if args.first.is_a?(Hash) && args.first['tenant_id']
    
    if tenant_id
      organization = Organization.find(tenant_id)
      ActsAsTenant.with_tenant(organization) do
        perform_with_tenant(*args)
      end
    else
      perform_with_tenant(*args)
    end
  end
  
  private
  
  def perform_with_tenant(*args)
    raise NotImplementedError, "Subclasses must implement perform_with_tenant"
  end
end

# Appointment Reminder Worker
class AppointmentReminderWorker < ApplicationWorker
  sidekiq_options queue: 'notifications', retry: 3, backtrace: true
  
  private
  
  def perform_with_tenant(appointment_id)
    appointment = Appointment.find(appointment_id)
    
    return unless appointment.pre_confirmed?
    
    # Check if appointment is about to expire (24 hours)
    if appointment.expires_at && appointment.expires_at <= 1.hour.from_now
      # Send expiration warning
      AppointmentMailer.expiration_warning(appointment).deliver_now
      
      # Schedule final expiration check
      AppointmentExpirationWorker.perform_in(1.hour, appointment_id)
    end
    
    # Send general reminder
    AppointmentMailer.reminder(appointment).deliver_now
    
    # Log the reminder
    Rails.logger.info "Appointment reminder sent for appointment #{appointment.id}"
    
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentReminderWorker: Appointment #{appointment_id} not found"
  rescue => e
    Rails.logger.error "AppointmentReminderWorker failed for appointment #{appointment_id}: #{e.message}"
    raise e
  end
end

# Email Notification Worker
class EmailNotificationWorker < ApplicationWorker
  sidekiq_options queue: 'mailers', retry: 5, backtrace: true
  
  private
  
  def perform_with_tenant(notification_type, appointment_id, additional_data = {})
    appointment = Appointment.find(appointment_id)
    
    case notification_type
    when 'appointment_confirmed'
      send_confirmation_email(appointment)
    when 'appointment_cancelled'
      send_cancellation_email(appointment)
    when 'appointment_completed'
      send_completion_email(appointment)
    when 'appointment_reminder'
      send_reminder_email(appointment)
    when 'credit_issued'
      send_credit_notification(appointment, additional_data)
    else
      Rails.logger.warn "Unknown notification type: #{notification_type}"
    end
    
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "EmailNotificationWorker: Appointment #{appointment_id} not found"
  rescue => e
    Rails.logger.error "EmailNotificationWorker failed for #{notification_type}, appointment #{appointment_id}: #{e.message}"
    raise e
  end
  
  private
  
  def send_confirmation_email(appointment)
    # Send to student/parent
    AppointmentMailer.confirmation_to_student(appointment).deliver_now
    
    # Send to professional
    AppointmentMailer.confirmation_to_professional(appointment).deliver_now
    
    Rails.logger.info "Confirmation emails sent for appointment #{appointment.id}"
  end
  
  def send_cancellation_email(appointment)
    # Send to student/parent
    AppointmentMailer.cancellation_to_student(appointment).deliver_now
    
    # Send to professional
    AppointmentMailer.cancellation_to_professional(appointment).deliver_now
    
    Rails.logger.info "Cancellation emails sent for appointment #{appointment.id}"
  end
  
  def send_completion_email(appointment)
    # Send completion notification to student/parent
    AppointmentMailer.completion_to_student(appointment).deliver_now
    
    Rails.logger.info "Completion email sent for appointment #{appointment.id}"
  end
  
  def send_reminder_email(appointment)
    # Send reminder to student/parent
    AppointmentMailer.reminder_to_student(appointment).deliver_now
    
    Rails.logger.info "Reminder email sent for appointment #{appointment.id}"
  end
  
  def send_credit_notification(appointment, additional_data)
    credit_amount = additional_data['credit_amount'] || 1
    
    # Send credit notification to student/parent
    AppointmentMailer.credit_issued(appointment, credit_amount).deliver_now
    
    Rails.logger.info "Credit notification sent for appointment #{appointment.id}, amount: #{credit_amount}"
  end
end

# Appointment Expiration Worker
class AppointmentExpirationWorker < ApplicationWorker
  sidekiq_options queue: 'critical', retry: 2, backtrace: true
  
  private
  
  def perform_with_tenant(appointment_id)
    appointment = Appointment.find(appointment_id)
    
    return unless appointment.pre_confirmed?
    
    if appointment.expires_at && appointment.expires_at <= Time.current
      # Expire the appointment
      appointment.cancel!
      
      # Send expiration notification
      EmailNotificationWorker.perform_async(
        'appointment_expired',
        appointment.id
      )
      
      Rails.logger.info "Appointment #{appointment.id} expired and cancelled"
    end
    
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentExpirationWorker: Appointment #{appointment_id} not found"
  rescue => e
    Rails.logger.error "AppointmentExpirationWorker failed for appointment #{appointment_id}: #{e.message}"
    raise e
  end
end