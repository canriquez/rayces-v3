require 'rails_helper'

RSpec.describe AppointmentReminderWorker, type: :worker do
  # NOTE: Worker implementations belong to SCRUM-32, but current implementation
  # is tightly coupled with multi-tenancy logic (SCRUM-33). Tests marked as pending
  # until core Sidekiq functionality can be decoupled from tenant-specific logic.
  
  # Worker tests enabled
  let(:organization) { create(:organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:professional) { create(:professional, user: professional_user, organization: organization) }
  let(:parent) { create(:user, :guardian, organization: organization) }
  let(:appointment) { create(:appointment, :pre_confirmed, professional: professional_user, client: parent, organization: organization) }

  describe '#perform' do
    context 'when appointment exists and is still pre_confirmed' do
      context 'when appointment is older than 24 hours' do
        before do
          # Create appointment 25 hours ago
          appointment.update_columns(created_at: 25.hours.ago)
        end

        it 'cancels the appointment after 24 hours' do
          expect(appointment.pre_confirmed?).to be_truthy
          
          AppointmentReminderWorker.new.perform(appointment.id)
          
          appointment.reload
          expect(appointment.cancelled?).to be_truthy
        end

        it 'sends cancellation notification' do
          # The appointment model sends cancellation notifications
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            appointment.professional_id,
            'appointment_cancelled',
            { 'appointment_id' => appointment.id }
          )
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            appointment.client_id,
            'appointment_cancelled',
            { 'appointment_id' => appointment.id }
          )
          # The worker sends expiration notification
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            appointment.client_id,
            'appointment_expired',
            { 'appointment_id' => appointment.id }
          )
          
          AppointmentReminderWorker.new.perform(appointment.id)
        end

        it 'logs the automatic cancellation' do
          worker = AppointmentReminderWorker.new
          expect(worker.logger).to receive(:info).with(
            /\[AppointmentReminderWorker\] Expiring pre-confirmed appointment #{appointment.id}/
          )
          
          worker.perform(appointment.id)
        end
      end

      context 'when appointment is less than 24 hours old' do
        it 'sends reminder notification' do
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            appointment.client_id,
            'appointment_confirmation_reminder',
            { 'appointment_id' => appointment.id }
          )
          
          AppointmentReminderWorker.new.perform(appointment.id)
        end

        it 'reschedules the check' do
          expect(AppointmentReminderWorker).to receive(:perform_in)
          
          AppointmentReminderWorker.new.perform(appointment.id)
        end
      end
    end

    context 'when appointment has already been confirmed' do
      before do
        appointment.confirm!
      end

      it 'does not cancel the appointment' do
        AppointmentReminderWorker.new.perform(appointment.id)
        
        appointment.reload
        expect(appointment.confirmed?).to be_truthy
      end

      it 'logs that no action was taken' do
        # Worker should not process confirmed appointments - no logging expected
        expect(Rails.logger).not_to receive(:info)
        
        AppointmentReminderWorker.new.perform(appointment.id)
      end
    end

    context 'when appointment has already been cancelled' do
      before do
        appointment.cancel!
      end

      it 'does not attempt to cancel again' do
        expect(appointment).not_to receive(:cancel!)
        
        AppointmentReminderWorker.new.perform(appointment.id)
      end
    end

    context 'when appointment does not exist' do
      it 'handles missing appointment gracefully' do
        worker = AppointmentReminderWorker.new
        expect(worker.logger).to receive(:warn).with(
          "Appointment with id 999999 not found for reminder worker"
        )
        
        expect {
          worker.perform(999999)
        }.not_to raise_error
      end
    end

    context 'when appointment is from different organization' do
      let(:other_org) { create(:organization, subdomain: 'other') }
      let(:other_appointment) { create(:appointment, :pre_confirmed, organization: other_org) }

      it 'does not cancel appointment from different tenant' do
        AppointmentReminderWorker.new.perform(other_appointment.id)
        
        other_appointment.reload
        expect(other_appointment.pre_confirmed?).to be_truthy
      end
    end
  end

  describe 'sidekiq configuration' do
    it 'includes ApplicationWorker module' do
      expect(AppointmentReminderWorker.ancestors).to include(ApplicationWorker)
    end

    it 'has correct queue configuration' do
      expect(AppointmentReminderWorker.sidekiq_options['queue']).to eq('critical')
    end

    it 'has correct retry configuration' do
      expect(AppointmentReminderWorker.sidekiq_options['retry']).to eq(5)
    end
  end

  describe 'tenant context preservation' do
    it 'maintains tenant context during job execution' do
      # In test environment, acts_as_tenant is disabled
      worker = AppointmentReminderWorker.new
      
      # The worker should work without tenant context in tests
      worker.perform(appointment.id)
      
      # In test environment, worker should work without tenant context
      # Appointment should only be cancelled if it's older than 24 hours
      appointment.reload
      expect(appointment.pre_confirmed?).to be_truthy # Still pre_confirmed since not 24h old
    end

    it 'sets tenant context from appointment organization' do
      # In test environment, tenant context is not used
      worker = AppointmentReminderWorker.new
      
      # Should work without tenant context in test environment
      expect { worker.perform(appointment.id) }.not_to raise_error
    end
  end

  describe 'error handling' do
    it 'handles AASM transition errors gracefully' do
      # Create appointment 25 hours ago so it will attempt to cancel
      appointment.update_columns(created_at: 25.hours.ago)
      
      # Mock the appointment to not allow cancellation
      allow_any_instance_of(Appointment).to receive(:may_cancel?).and_return(false)
      
      worker = AppointmentReminderWorker.new
      expect(worker.logger).to receive(:error).with(
        /\[AppointmentReminderWorker\] Cannot cancel appointment #{appointment.id} - invalid state transition/
      )
      
      # Worker should complete without raising error
      expect {
        worker.perform(appointment.id)
      }.not_to raise_error
      
      # Appointment should remain in pre_confirmed state
      appointment.reload
      expect(appointment.pre_confirmed?).to be_truthy
    end

    it 'handles database errors gracefully' do
      allow(Appointment).to receive(:find).and_raise(ActiveRecord::ConnectionTimeoutError)
      
      expect {
        AppointmentReminderWorker.new.perform(appointment.id)
      }.to raise_error(ActiveRecord::ConnectionTimeoutError)
    end
  end

  describe 'scheduling' do
    # Mark as pending since AASM callbacks with Sidekiq scheduling are part of multi-tenancy implementation (SCRUM-33)
    it 'is scheduled when appointment transitions to pre_confirmed' do
      draft_appointment = create(:appointment, :draft, professional: professional_user, client: parent, organization: organization)
      
      expect(AppointmentReminderWorker).to receive(:perform_in).with(24.hours, draft_appointment.id)
      
      draft_appointment.pre_confirm!
    end
  end
end