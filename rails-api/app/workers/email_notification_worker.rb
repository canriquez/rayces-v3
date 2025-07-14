# app/workers/email_notification_worker.rb
class EmailNotificationWorker < ApplicationWorker
  sidekiq_options queue: 'mailers', retry: 3
  
  def perform(user_id, notification_type, params = {})
    with_error_handling do
      user = User.find(user_id)
      
      # Ensure we're in the correct tenant context (only if acts_as_tenant is enabled)
      if Rails.env.test?
        process_notification(user, user_id, notification_type, params)
      else
        ActsAsTenant.with_tenant(user.organization) do
          process_notification(user, user_id, notification_type, params)
        end
      end
    end
  end

  private

  def process_notification(user, user_id, notification_type, params)
    log_info("Sending #{notification_type} notification to user #{user_id}")
    
    case notification_type
    when 'appointment_confirmation_reminder'
      send_appointment_reminder(user, params)
    when 'appointment_confirmed'
      send_appointment_confirmed(user, params)
    when 'appointment_expired'
      send_appointment_expired(user, params)
    when 'appointment_cancelled'
      send_appointment_cancelled(user, params)
    when 'welcome'
      send_welcome_email(user, params)
    else
      log_error("Unknown notification type: #{notification_type}")
    end
  end
  
  def send_appointment_reminder(user, params)
    # In a real application, this would use ActionMailer
    # For now, we'll just log the action
    appointment = Appointment.find(params['appointment_id'])
    log_info("Would send appointment reminder email to #{user.email} for appointment #{appointment.id}")
    
    # Example ActionMailer call (when implemented):
    # AppointmentMailer.confirmation_reminder(user, appointment).deliver_later
  end
  
  def send_appointment_confirmed(user, params)
    appointment = Appointment.find(params['appointment_id'])
    log_info("Would send appointment confirmation email to #{user.email} for appointment #{appointment.id}")
  end
  
  def send_appointment_expired(user, params)
    appointment = Appointment.find(params['appointment_id'])
    log_info("Would send appointment expiration email to #{user.email} for appointment #{appointment.id}")
  end
  
  def send_appointment_cancelled(user, params)
    appointment = Appointment.find(params['appointment_id'])
    log_info("Would send appointment cancellation email to #{user.email} for appointment #{appointment.id}")
  end
  
  def send_welcome_email(user, params)
    log_info("Would send welcome email to #{user.email}")
  end
end