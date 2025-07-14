# app/workers/appointment_reminder_worker.rb
class AppointmentReminderWorker < ApplicationWorker
  sidekiq_options queue: 'critical', retry: 5
  
  def perform(appointment_id)
    with_error_handling do
      appointment = Appointment.find(appointment_id)
      
      # Ensure we're in the correct tenant context (only if acts_as_tenant is enabled)
      if Rails.env.test?
        process_appointment(appointment, appointment_id)
      else
        ActsAsTenant.with_tenant(appointment.organization) do
          process_appointment(appointment, appointment_id)
        end
      end
    end
  end

  private

  def process_appointment(appointment, appointment_id)
    # Check if appointment is still in pre_confirmed state
    return unless appointment.pre_confirmed?
    
    # Check if 24 hours have passed without confirmation
    if appointment.created_at < 24.hours.ago
      log_info("Expiring pre-confirmed appointment #{appointment_id}")
      appointment.cancel!
      
      # Notify client about expiration
      EmailNotificationWorker.perform_async(
        appointment.client_id,
        'appointment_expired',
        { appointment_id: appointment_id }
      )
    else
      # Send reminder notification
      log_info("Sending reminder for appointment #{appointment_id}")
      
      # Notify client to confirm appointment
      EmailNotificationWorker.perform_async(
        appointment.client_id,
        'appointment_confirmation_reminder',
        { appointment_id: appointment_id }
      )
      
      # Reschedule check for later
      remaining_hours = 24 - ((Time.current - appointment.created_at) / 1.hour).to_i
      if remaining_hours > 0
        self.class.perform_in(remaining_hours.hours, appointment_id)
      end
    end
  end
end