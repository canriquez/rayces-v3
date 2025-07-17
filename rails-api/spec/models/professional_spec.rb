require 'rails_helper'

RSpec.describe Professional, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:user) }
    it { should validate_numericality_of(:session_duration_minutes).is_greater_than(0) }
    it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:appointments) }
  end

  describe 'JSON serialization' do
    let(:professional) { create(:professional) }

    it 'serializes availability as JSON' do
      expect(professional.availability).to be_a(Hash)
      expect(professional.availability['monday']).to be_present
    end

    it 'serializes settings as JSON' do
      expect(professional.settings).to be_a(Hash)
      expect(professional.settings['languages']).to be_an(Array)
    end

    it 'allows updating availability' do
      new_availability = {
        "monday" => { "start" => "08:00", "end" => "16:00" },
        "friday" => { "start" => "09:00", "end" => "13:00" }
      }
      professional.update!(availability: new_availability)
      professional.reload
      expect(professional.availability['monday']['start']).to eq('08:00')
      expect(professional.availability['friday']['end']).to eq('13:00')
    end
  end

  describe 'availability methods' do
    let(:professional) { create(:professional) }

    describe '#available_on?' do
      it 'returns true for days in availability' do
        # NOTE: Method signature doesn't match test expectations
        expect(professional.available_on?('monday')).to be_truthy
        expect(professional.available_on?('tuesday')).to be_truthy
      end

      it 'returns false for days not in availability' do
        expect(professional.available_on?('saturday')).to be_falsy
        expect(professional.available_on?('sunday')).to be_falsy
      end
    end

    describe '#available_at?' do
      it 'returns true for times within availability' do
        # NOTE: Method not implemented yet
        monday_10am = next_weekday('monday').to_time.change(hour: 10, min: 0)
        expect(professional.available_at?(monday_10am)).to be_truthy
      end

      it 'returns false for times outside availability' do
        monday_6am = next_weekday('monday').to_time.change(hour: 6, min: 0)
        monday_8pm = next_weekday('monday').to_time.change(hour: 20, min: 0)
        
        expect(professional.available_at?(monday_6am)).to be_falsy
        expect(professional.available_at?(monday_8pm)).to be_falsy
      end

      it 'returns false for unavailable days' do
        saturday_10am = next_weekday('saturday').to_time.change(hour: 10, min: 0)
        expect(professional.available_at?(saturday_10am)).to be_falsy
      end
    end
  end

  describe 'appointment conflicts' do
    let(:professional) { create(:professional) }
    let(:client) { create(:user, :guardian, organization: professional.organization) }

    describe '#has_conflicting_appointment?' do
      let(:appointment_time) { next_weekday('monday').to_time.change(hour: 10, min: 0) }

      before do
        create(:appointment, :confirmed,
          professional: professional.user,
          client: client,
          organization: professional.organization,
          scheduled_at: appointment_time,
          duration_minutes: 60
        )
      end

      it 'detects exact time conflicts' do
        expect(professional.has_conflicting_appointment?(appointment_time, 60)).to be_truthy
      end

      it 'detects overlapping conflicts' do
        overlap_time = appointment_time + 30.minutes
        expect(professional.has_conflicting_appointment?(overlap_time, 60)).to be_truthy
      end

      it 'allows non-overlapping appointments' do
        later_time = appointment_time + 60.minutes
        expect(professional.has_conflicting_appointment?(later_time, 60)).to be_falsy
      end

      it 'ignores draft appointments for conflicts' do
        create(:appointment, :draft,
          professional: professional.user,
          client: client,
          organization: professional.organization,
          scheduled_at: appointment_time + 2.hours,
          duration_minutes: 60
        )
        
        conflict_time = appointment_time + 2.hours + 30.minutes
        expect(professional.has_conflicting_appointment?(conflict_time, 60)).to be_falsy
      end

      it 'ignores cancelled appointments for conflicts' do
        create(:appointment, :cancelled,
          professional: professional.user,
          client: client,
          organization: professional.organization,
          scheduled_at: appointment_time + 3.hours,
          duration_minutes: 60
        )
        
        conflict_time = appointment_time + 3.hours + 30.minutes
        expect(professional.has_conflicting_appointment?(conflict_time, 60)).to be_falsy
      end
    end
  end

  describe 'delegate methods' do
    let(:user) { create(:user, :professional, first_name: 'Dr. Jane', last_name: 'Smith') }
    let(:professional) { create(:professional, user: user) }

    it 'delegates name methods to user' do
      expect(professional.first_name).to eq('Dr. Jane')
      expect(professional.last_name).to eq('Smith')
      expect(professional.full_name).to eq('Dr. Jane Smith')
    end

    it 'delegates contact methods to user' do
      expect(professional.email).to eq(user.email)
      expect(professional.phone).to eq(user.phone)
    end
  end

  describe 'factories' do
    it 'creates valid professionals' do
      professional = build(:professional)
      expect(professional).to be_valid
    end

    it 'creates specialized professionals' do
      psychologist = create(:professional, :psychologist)
      speech_therapist = create(:professional, :speech_therapist)

      expect(psychologist.specialization).to eq('Psychology')
      expect(speech_therapist.specialization).to eq('Speech Therapy')
      expect(speech_therapist.session_duration_minutes).to eq(45)
    end
  end

  describe 'scopes' do
    let!(:psychologist) { create(:professional, :psychologist) }
    let!(:speech_therapist) { create(:professional, :speech_therapist) }

    it 'can filter by specialization' do
      psychology_professionals = Professional.where(specialization: 'Psychology')
      expect(psychology_professionals).to include(psychologist)
      expect(psychology_professionals).not_to include(speech_therapist)
    end
  end

  private

  def next_weekday(day_name)
    day_index = Date::DAYNAMES.index(day_name.capitalize)
    today = Date.current
    days_until = (day_index - today.wday) % 7
    days_until = 7 if days_until == 0 # If today is the target day, get next week
    today + days_until.days
  end
end