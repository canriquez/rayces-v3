require 'rails_helper'

RSpec.describe Appointment, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:professional) }
    it { should validate_presence_of(:client) }
    it { should validate_presence_of(:scheduled_at) }
    it { should validate_presence_of(:duration_minutes) }
    
    it { should validate_numericality_of(:duration_minutes).is_greater_than(0) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:professional) }
    it { should belong_to(:client).class_name('User') }
    it { should belong_to(:student).optional }
  end


  describe 'AASM state machine' do
    let(:appointment) { create(:appointment, :draft) }

    describe 'states' do
      it 'starts in draft state' do
        expect(appointment.state).to eq('draft')
        expect(appointment.draft?).to be_truthy
      end

      it 'defines all expected states' do
        expect(Appointment.aasm.states.map(&:name)).to contain_exactly(
          :draft, :pre_confirmed, :confirmed, :executed, :cancelled
        )
      end
    end

    describe 'transitions' do
      context 'from draft state' do
        it 'can transition to pre_confirmed' do
          expect(appointment.may_pre_confirm?).to be_truthy
          appointment.pre_confirm!
          expect(appointment.pre_confirmed?).to be_truthy
        end

        it 'can transition to cancelled' do
          expect(appointment.may_cancel?).to be_truthy
          appointment.cancel!
          expect(appointment.cancelled?).to be_truthy
        end

        it 'cannot directly transition to confirmed' do
          expect(appointment.may_confirm?).to be_falsy
        end

        it 'cannot directly transition to executed' do
          expect(appointment.may_execute?).to be_falsy
        end
      end

      context 'from pre_confirmed state' do
        before { appointment.pre_confirm! }

        it 'can transition to confirmed' do
          expect(appointment.may_confirm?).to be_truthy
          appointment.confirm!
          expect(appointment.confirmed?).to be_truthy
        end

        it 'can transition to cancelled' do
          expect(appointment.may_cancel?).to be_truthy
          appointment.cancel!
          expect(appointment.cancelled?).to be_truthy
        end

        it 'cannot transition to executed' do
          expect(appointment.may_execute?).to be_falsy
        end
      end

      context 'from confirmed state' do
        before do
          appointment.pre_confirm!
          appointment.confirm!
        end

        it 'can transition to executed' do
          # Update appointment time to past for execution to be allowed
          appointment.update_column(:scheduled_at, 1.hour.ago)
          expect(appointment.may_execute?).to be_truthy
          appointment.execute!
          expect(appointment.executed?).to be_truthy
        end

        it 'can transition to cancelled' do
          expect(appointment.may_cancel?).to be_truthy
          appointment.cancel!
          expect(appointment.cancelled?).to be_truthy
        end
      end

      context 'from executed state' do
        before do
          appointment.pre_confirm!
          appointment.confirm!
          # Update appointment time to past for execution to be allowed
          appointment.update_column(:scheduled_at, 1.hour.ago)
          appointment.execute!
        end

        it 'cannot transition to any other state' do
          expect(appointment.may_cancel?).to be_falsy
          expect(appointment.may_confirm?).to be_falsy
          expect(appointment.may_pre_confirm?).to be_falsy
        end
      end

      context 'from cancelled state' do
        before { appointment.cancel! }

        it 'cannot transition to any other state' do
          expect(appointment.may_confirm?).to be_falsy
          expect(appointment.may_execute?).to be_falsy
          expect(appointment.may_pre_confirm?).to be_falsy
        end
      end
    end

    describe 'callbacks' do
      it 'triggers background job on pre_confirm' do
        expect(AppointmentReminderWorker).to receive(:perform_in).with(24.hours, appointment.id)
        appointment.pre_confirm!
      end

      it 'triggers email notification on confirm' do
        appointment.pre_confirm!
        expect(EmailNotificationWorker).to receive(:perform_async).with(
          appointment.professional_id, 'appointment_confirmed', { 'appointment_id' => appointment.id }
        )
        expect(EmailNotificationWorker).to receive(:perform_async).with(
          appointment.client_id, 'appointment_confirmed', { 'appointment_id' => appointment.id }
        )
        appointment.confirm!
      end

      it 'logs execution' do
        appointment.pre_confirm!
        appointment.confirm!
        # Update appointment time to past for execution to be allowed
        appointment.update_column(:scheduled_at, 1.hour.ago)
        expect(Rails.logger).to receive(:info).with("Appointment #{appointment.id} executed at #{Time.current}")
        appointment.execute!
      end

      it 'triggers email notification on cancel' do
        expect(EmailNotificationWorker).to receive(:perform_async).with(
          appointment.professional_id, 'appointment_cancelled', { 'appointment_id' => appointment.id }
        )
        expect(EmailNotificationWorker).to receive(:perform_async).with(
          appointment.client_id, 'appointment_cancelled', { 'appointment_id' => appointment.id }
        )
        appointment.cancel!
      end
    end
  end

  describe 'scopes' do
    let!(:draft_appointment) { create(:appointment, :draft) }
    let!(:confirmed_appointment) { create(:appointment, :confirmed) }
    let!(:executed_appointment) { create(:appointment, :executed) }
    let!(:cancelled_appointment) { create(:appointment, :cancelled) }

    it 'filters by state' do
      expect(Appointment.draft).to include(draft_appointment)
      expect(Appointment.confirmed).to include(confirmed_appointment)
      expect(Appointment.executed).to include(executed_appointment)
      expect(Appointment.cancelled).to include(cancelled_appointment)
    end
  end

  describe 'business logic validations' do
    let(:professional) { create(:professional) }
    let(:client) { create(:user, :guardian, organization: professional.organization) }

    it 'validates appointment is not in the past' do
      past_appointment = build(:appointment,
        professional: professional.user,
        client: client,
        organization: professional.organization,
        scheduled_at: 1.day.ago
      )
      expect(past_appointment).not_to be_valid
      expect(past_appointment.errors[:scheduled_at]).to include("must be in the future")
    end

    it 'validates professional availability' do
      # NOTE: Professional availability validation is not yet implemented
      # Create appointment on Sunday (not in availability)
      sunday_appointment = build(:appointment,
        professional: professional.user,
        client: client,
        organization: professional.organization,
        scheduled_at: next_sunday_at_10am
      )
      expect(sunday_appointment).not_to be_valid
      expect(sunday_appointment.errors[:scheduled_at]).to include("Professional is not available at this time")
    end

    it 'validates no conflicting appointments' do
      scheduled_time = next_monday_at_10am
      
      # Create first appointment
      create(:appointment, :confirmed,
        professional: professional.user,
        client: client,
        organization: professional.organization,
        scheduled_at: scheduled_time,
        duration_minutes: 60
      )
      
      # Try to create conflicting appointment
      conflicting_appointment = build(:appointment,
        professional: professional.user,
        client: client,
        organization: professional.organization,
        scheduled_at: scheduled_time + 30.minutes,
        duration_minutes: 60
      )
      
      expect(conflicting_appointment).not_to be_valid
      expect(conflicting_appointment.errors[:scheduled_at]).to include("conflicts with another appointment")
    end
  end

  describe 'factories' do
    it 'creates appointments in different states' do
      draft = create(:appointment, :draft)
      pre_confirmed = create(:appointment, :pre_confirmed)
      confirmed = create(:appointment, :confirmed)
      executed = create(:appointment, :executed)
      cancelled = create(:appointment, :cancelled)

      expect(draft.draft?).to be_truthy
      expect(pre_confirmed.pre_confirmed?).to be_truthy
      expect(confirmed.confirmed?).to be_truthy
      expect(executed.executed?).to be_truthy
      expect(cancelled.cancelled?).to be_truthy
    end
  end

  private

  def next_monday_at_10am
    today = Date.current
    days_until_monday = (1 - today.wday) % 7
    days_until_monday = 7 if days_until_monday == 0 # If today is Monday, get next Monday
    (today + days_until_monday.days).to_time.change(hour: 10, min: 0)
  end

  def next_sunday_at_10am
    today = Date.current
    days_until_sunday = (7 - today.wday) % 7
    days_until_sunday = 7 if days_until_sunday == 0 # If today is Sunday, get next Sunday
    (today + days_until_sunday.days).to_time.change(hour: 10, min: 0)
  end
end