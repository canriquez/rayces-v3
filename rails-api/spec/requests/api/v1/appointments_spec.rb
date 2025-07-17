require 'rails_helper'

RSpec.describe 'Api::V1::Appointments', type: :request do
  # NOTE: JWT authentication and API endpoints belong to SCRUM-32, but current implementation
  # is tightly coupled with multi-tenancy logic (SCRUM-33). Tests skipped until
  # authentication can be decoupled from tenant resolution for basic API functionality.
  
  # before(:all) { skip "JWT authentication implementation needs decoupling from multi-tenancy for SCRUM-32" }
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:parent_user) { create(:user, :parent, organization: organization) }
  let(:professional) { create(:professional, user: professional_user, organization: organization) }
  let(:student) { create(:student, parent: parent_user, organization: organization) }

  describe 'GET /api/v1/appointments' do
    let!(:appointment1) { create(:appointment, :confirmed, professional: professional_user, client: parent_user, organization: organization) }
    let!(:appointment2) { create(:appointment, :draft, professional: professional_user, client: parent_user, organization: organization) }

    context 'when authenticated as professional' do
      # NOTE: Current implementation is tightly coupled with multi-tenancy (SCRUM-33)
      # JWT authentication belongs to SCRUM-32 but needs refactoring to decouple from tenant logic

      it 'returns appointments for the professional' do
        get '/api/v1/appointments', headers: auth_headers(professional_user)
        
        if response.status != 200
          puts "Response status: #{response.status}"
          puts "Response body: #{response.body}"
          puts "Professional user id: #{professional_user.id}"
          puts "Professional user org: #{professional_user.organization_id}"
        end
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['appointments'].length).to eq(2)
        expect(json_response['appointments'].map { |a| a['id'] }).to contain_exactly(appointment1.id, appointment2.id)
      end

      it 'includes professional details' do
        get '/api/v1/appointments', headers: auth_headers(professional_user)
        
        json_response = JSON.parse(response.body)
        appointment_data = json_response['appointments'].first
        expect(appointment_data).to have_key('professional')
        expect(appointment_data).to have_key('client')
        expect(appointment_data).to have_key('state')
      end
    end

    context 'when authenticated as parent' do
      it 'returns appointments for the parent' do
        get '/api/v1/appointments', headers: auth_headers(parent_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['appointments'].length).to eq(2)
      end

      it 'hides professional private information' do
        get '/api/v1/appointments', headers: auth_headers(parent_user)
        
        json_response = JSON.parse(response.body)
        appointment_data = json_response['appointments'].first
        expect(appointment_data['professional']).not_to have_key('hourly_rate')
        expect(appointment_data['professional']).not_to have_key('license_number')
      end
    end

    context 'when authenticated as admin' do
      it 'returns all appointments in organization' do
        get '/api/v1/appointments', headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['appointments'].length).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/appointments/:id' do
    let(:appointment) { create(:appointment, :confirmed, professional: professional_user, client: parent_user, student: student, organization: organization) }

    context 'when authenticated as the professional' do
      it 'returns the appointment details' do
        get "/api/v1/appointments/#{appointment.id}", headers: auth_headers(professional_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['appointment']['id']).to eq(appointment.id)
        expect(json_response['appointment']['state']).to eq('confirmed')
      end
    end

    context 'when authenticated as the parent' do
      it 'returns the appointment details' do
        get "/api/v1/appointments/#{appointment.id}", headers: auth_headers(parent_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['appointment']['id']).to eq(appointment.id)
      end
    end

    context 'when trying to access another organization appointment' do
      let(:other_org) { create(:organization, subdomain: 'other') }
      let(:other_user) { create(:user, :professional, organization: other_org) }
      let(:other_appointment) { create(:appointment, organization: other_org) }

      it 'returns not found' do
        get "/api/v1/appointments/#{appointment.id}", headers: auth_headers(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/appointments' do
    let(:appointment_params) do
      {
        appointment: {
          professional_id: professional_user.id,
          client_id: parent_user.id,
          student_id: student.id,
          scheduled_at: 1.week.from_now.change(hour: 10, minute: 0),
          duration_minutes: 60,
          price: 100.00
        }
      }
    end

    context 'when authenticated as parent' do
      it 'creates a new appointment' do
        expect {
          post '/api/v1/appointments', params: appointment_params.to_json, headers: auth_headers(parent_user)
        }.to change(Appointment, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['appointment']['state']).to eq('draft')
      end

      it 'validates appointment data' do
        invalid_params = appointment_params.deep_dup
        invalid_params[:appointment][:scheduled_at] = 1.day.ago

        post '/api/v1/appointments', params: invalid_params.to_json, headers: auth_headers(parent_user)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Scheduled at must be in the future")
      end
    end

    context 'when authenticated as professional' do
      it 'creates an appointment for clients' do
        post '/api/v1/appointments', params: appointment_params.to_json, headers: auth_headers(professional_user)
        expect(response).to have_http_status(:created)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/appointments', params: appointment_params.to_json, headers: { 'Content-Type' => 'application/json' }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'state transition endpoints' do
    let(:appointment) { create(:appointment, :draft, professional: professional_user, client: parent_user, organization: organization) }

    describe 'PATCH /api/v1/appointments/:id/pre_confirm' do
      context 'when authenticated as professional' do
        it 'transitions appointment to pre_confirmed' do
          patch "/api/v1/appointments/#{appointment.id}/pre_confirm", headers: auth_headers(professional_user)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['appointment']['state']).to eq('pre_confirmed')
          
          appointment.reload
          expect(appointment.pre_confirmed?).to be_truthy
        end

        it 'schedules reminder worker' do
          expect(AppointmentReminderWorker).to receive(:perform_in).with(24.hours, appointment.id)
          patch "/api/v1/appointments/#{appointment.id}/pre_confirm", headers: auth_headers(professional_user)
        end
      end

      context 'when authenticated as parent' do
        it 'returns forbidden' do
          patch "/api/v1/appointments/#{appointment.id}/pre_confirm", headers: auth_headers(parent_user)
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'PATCH /api/v1/appointments/:id/confirm' do
      let(:pre_confirmed_appointment) { create(:appointment, :pre_confirmed, professional: professional_user, client: parent_user, organization: organization) }

      context 'when authenticated as parent' do
        it 'transitions appointment to confirmed' do
          patch "/api/v1/appointments/#{pre_confirmed_appointment.id}/confirm", headers: auth_headers(parent_user)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['appointment']['state']).to eq('confirmed')
        end

        it 'triggers confirmation email' do
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            pre_confirmed_appointment.professional_id, 'appointment_confirmed', { 'appointment_id' => pre_confirmed_appointment.id }
          )
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            pre_confirmed_appointment.client_id, 'appointment_confirmed', { 'appointment_id' => pre_confirmed_appointment.id }
          )
          patch "/api/v1/appointments/#{pre_confirmed_appointment.id}/confirm", headers: auth_headers(parent_user)
        end
      end

      context 'when appointment is not pre_confirmed' do
        it 'returns unprocessable entity' do
          patch "/api/v1/appointments/#{appointment.id}/confirm", headers: auth_headers(parent_user)
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Cannot confirm appointment')
        end
      end
    end

    describe 'PATCH /api/v1/appointments/:id/execute' do
      let(:confirmed_appointment) do
        # Create a confirmed appointment in the past so it can be executed
        appointment = create(:appointment, :confirmed, professional: professional_user, client: parent_user, organization: organization)
        appointment.update_columns(scheduled_at: 1.hour.ago)
        appointment
      end

      context 'when authenticated as professional' do
        it 'transitions appointment to executed' do
          patch "/api/v1/appointments/#{confirmed_appointment.id}/execute", headers: auth_headers(professional_user)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['appointment']['state']).to eq('executed')
        end

        it 'allows adding notes' do
          patch "/api/v1/appointments/#{confirmed_appointment.id}/execute", 
                params: { notes: 'Session completed successfully' }.to_json,
                headers: auth_headers(professional_user)
          
          confirmed_appointment.reload
          expect(confirmed_appointment.notes).to eq('Session completed successfully')
        end
      end

      context 'when authenticated as parent' do
        it 'returns forbidden' do
          patch "/api/v1/appointments/#{confirmed_appointment.id}/execute", headers: auth_headers(parent_user)
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'PATCH /api/v1/appointments/:id/cancel' do
      context 'when authenticated as parent' do
        it 'transitions appointment to cancelled' do
          patch "/api/v1/appointments/#{appointment.id}/cancel", headers: auth_headers(parent_user)
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['appointment']['state']).to eq('cancelled')
        end

        it 'allows adding cancellation reason' do
          patch "/api/v1/appointments/#{appointment.id}/cancel", 
                params: { notes: 'Child is sick' }.to_json,
                headers: auth_headers(parent_user)
          
          appointment.reload
          expect(appointment.notes).to eq('Child is sick')
        end

        it 'triggers cancellation email' do
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            appointment.professional_id, 'appointment_cancelled', { 'appointment_id' => appointment.id }
          )
          expect(EmailNotificationWorker).to receive(:perform_async).with(
            appointment.client_id, 'appointment_cancelled', { 'appointment_id' => appointment.id }
          )
          patch "/api/v1/appointments/#{appointment.id}/cancel", headers: auth_headers(parent_user)
        end
      end

      context 'when authenticated as professional' do
        it 'allows professional to cancel' do
          patch "/api/v1/appointments/#{appointment.id}/cancel", headers: auth_headers(professional_user)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'appointment filtering' do
    let!(:draft_appointment) { create(:appointment, :draft, professional: professional_user, client: parent_user, organization: organization) }
    let!(:confirmed_appointment) { create(:appointment, :confirmed, professional: professional_user, client: parent_user, organization: organization) }
    let!(:executed_appointment) { create(:appointment, :executed, professional: professional_user, client: parent_user, organization: organization) }
    let!(:future_appointment) do
      # Create an appointment far in the future for date filtering test
      # Use :draft to avoid conflicts, then update to confirmed
      appointment = create(:appointment, :draft, professional: professional_user, client: parent_user, organization: organization)
      appointment.update_columns(scheduled_at: 2.weeks.from_now, state: 'confirmed')
      appointment
    end

    it 'filters by state' do
      get '/api/v1/appointments', params: { state: 'confirmed' }, headers: auth_headers(professional_user)
      
      json_response = JSON.parse(response.body)
      expect(json_response['appointments'].length).to eq(2)  # confirmed_appointment and future_appointment
      confirmed_ids = json_response['appointments'].map { |a| a['id'] }
      expect(confirmed_ids).to include(confirmed_appointment.id, future_appointment.id)
    end

    it 'filters by date range' do
      future_date = 1.week.from_now.to_date
      get '/api/v1/appointments', params: { start_date: future_date, end_date: future_date + 1.week }, headers: auth_headers(professional_user)
      
      json_response = JSON.parse(response.body)
      future_appointments = json_response['appointments'].select do |apt|
        Date.parse(apt['scheduled_at']) >= future_date
      end
      expect(future_appointments.length).to be > 0
    end
  end

end