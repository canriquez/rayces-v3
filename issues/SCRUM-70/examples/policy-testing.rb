# RSpec Testing Examples for Pundit Policies
# Shows comprehensive testing patterns for multi-tenant authorization

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe OrganizationPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  
  # Test different user roles
  context 'for an admin user' do
    let(:user) { create(:user, :admin, organization: organization) }
    let(:policy) { described_class.new(user, organization) }
    
    it 'allows viewing own organization' do
      expect(policy.show?).to be true
    end
    
    it 'denies viewing other organizations' do
      other_policy = described_class.new(user, other_organization)
      expect(other_policy.show?).to be false
    end
    
    it 'allows updating own organization' do
      expect(policy.update?).to be true
    end
    
    it 'denies updating other organizations' do
      other_policy = described_class.new(user, other_organization)
      expect(other_policy.update?).to be false
    end
    
    it 'denies destroying any organization' do
      expect(policy.destroy?).to be false
    end
  end
  
  context 'for a professional user' do
    let(:user) { create(:user, :professional, organization: organization) }
    let(:policy) { described_class.new(user, organization) }
    
    it 'allows viewing own organization' do
      expect(policy.show?).to be true
    end
    
    it 'denies updating organization' do
      expect(policy.update?).to be false
    end
  end
  
  context 'for a secretary user' do
    let(:user) { create(:user, :secretary, organization: organization) }
    
    permissions :show? do
      it 'grants access to own organization' do
        expect(subject).to permit(user, organization)
      end
      
      it 'denies access to other organizations' do
        expect(subject).not_to permit(user, other_organization)
      end
    end
    
    permissions :update? do
      it 'denies update access' do
        expect(subject).not_to permit(user, organization)
      end
    end
  end
  
  context 'for a client user' do
    let(:user) { create(:user, :client, organization: organization) }
    
    permissions :index?, :show? do
      it 'grants read access to own organization' do
        expect(subject).to permit(user, organization)
      end
    end
    
    permissions :create?, :update?, :destroy? do
      it 'denies write access' do
        expect(subject).not_to permit(user, organization)
      end
    end
  end
  
  describe 'Scope' do
    let(:admin) { create(:user, :admin, organization: organization) }
    let(:scope) { described_class::Scope.new(admin, Organization).resolve }
    
    it 'returns only the user\'s organization' do
      other_organization # create it
      expect(scope).to contain_exactly(organization)
    end
  end
end

RSpec.describe AppointmentPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:professional) { create(:professional, organization: organization) }
  let(:student) { create(:student, organization: organization) }
  let(:appointment) { create(:appointment, organization: organization, professional: professional, student: student) }
  
  describe 'permissions matrix' do
    subject { described_class }
    
    context 'admin user' do
      let(:admin) { create(:user, :admin, organization: organization) }
      
      permissions :index?, :show?, :create?, :update? do
        it 'grants full access to appointments in same organization' do
          expect(subject).to permit(admin, appointment)
        end
      end
      
      permissions :pre_confirm?, :confirm?, :execute?, :cancel? do
        it 'grants state transition permissions' do
          expect(subject).to permit(admin, appointment)
        end
      end
      
      it 'denies access to appointments in other organizations' do
        other_appointment = create(:appointment)
        expect(subject).not_to permit(admin, other_appointment)
      end
    end
    
    context 'professional user' do
      let(:professional_user) { create(:user, :professional, organization: organization) }
      let(:assigned_appointment) { create(:appointment, professional: professional_user.professional_profile, organization: organization) }
      let(:unassigned_appointment) { create(:appointment, organization: organization) }
      
      permissions :show? do
        it 'grants access to assigned appointments' do
          expect(subject).to permit(professional_user, assigned_appointment)
        end
        
        it 'denies access to unassigned appointments' do
          expect(subject).not_to permit(professional_user, unassigned_appointment)
        end
      end
      
      permissions :create? do
        it 'denies appointment creation' do
          expect(subject).not_to permit(professional_user, appointment)
        end
      end
      
      permissions :execute? do
        it 'allows executing assigned confirmed appointments' do
          assigned_appointment.confirm!
          expect(subject).to permit(professional_user, assigned_appointment)
        end
        
        it 'denies executing unconfirmed appointments' do
          expect(subject).not_to permit(professional_user, assigned_appointment)
        end
      end
    end
    
    context 'secretary user' do
      let(:secretary) { create(:user, :secretary, organization: organization) }
      
      permissions :index?, :show?, :create?, :update? do
        it 'grants management access to all appointments in organization' do
          expect(subject).to permit(secretary, appointment)
        end
      end
      
      permissions :confirm? do
        it 'allows confirming pre-confirmed appointments' do
          appointment.pre_confirm!
          expect(subject).to permit(secretary, appointment)
        end
      end
      
      permissions :execute? do
        it 'denies executing appointments' do
          appointment.confirm!
          expect(subject).not_to permit(secretary, appointment)
        end
      end
    end
    
    context 'client user' do
      let(:client) { create(:user, :client, organization: organization) }
      let(:client_appointment) { create(:appointment, client: client, organization: organization) }
      let(:other_appointment) { create(:appointment, organization: organization) }
      
      permissions :show? do
        it 'grants access to own appointments' do
          expect(subject).to permit(client, client_appointment)
        end
        
        it 'denies access to other appointments' do
          expect(subject).not_to permit(client, other_appointment)
        end
      end
      
      permissions :create? do
        it 'allows creating appointments' do
          new_appointment = build(:appointment, client: client, organization: organization)
          expect(subject).to permit(client, new_appointment)
        end
      end
      
      permissions :cancel? do
        it 'allows cancelling own appointments within cancellation window' do
          allow(client_appointment).to receive(:cancellable_by_client?).and_return(true)
          expect(subject).to permit(client, client_appointment)
        end
        
        it 'denies cancelling appointments outside cancellation window' do
          allow(client_appointment).to receive(:cancellable_by_client?).and_return(false)
          expect(subject).not_to permit(client, client_appointment)
        end
      end
    end
  end
  
  describe 'Scope' do
    let(:organization) { create(:organization) }
    let(:other_organization) { create(:organization) }
    
    let(:admin) { create(:user, :admin, organization: organization) }
    let(:professional_user) { create(:user, :professional, organization: organization) }
    let(:secretary) { create(:user, :secretary, organization: organization) }
    let(:client) { create(:user, :client, organization: organization) }
    
    let!(:org_appointments) { create_list(:appointment, 3, organization: organization) }
    let!(:other_org_appointments) { create_list(:appointment, 2, organization: other_organization) }
    let!(:professional_appointments) { create_list(:appointment, 2, professional: professional_user.professional_profile, organization: organization) }
    let!(:client_appointments) { create_list(:appointment, 2, client: client, organization: organization) }
    
    it 'scopes appointments for admin to organization' do
      scope = described_class::Scope.new(admin, Appointment).resolve
      expect(scope).to match_array(org_appointments + professional_appointments + client_appointments)
    end
    
    it 'scopes appointments for professional to assigned only' do
      scope = described_class::Scope.new(professional_user, Appointment).resolve
      expect(scope).to match_array(professional_appointments)
    end
    
    it 'scopes appointments for secretary to organization' do
      scope = described_class::Scope.new(secretary, Appointment).resolve
      expect(scope).to match_array(org_appointments + professional_appointments + client_appointments)
    end
    
    it 'scopes appointments for client to own appointments' do
      scope = described_class::Scope.new(client, Appointment).resolve
      expect(scope).to match_array(client_appointments)
    end
    
    it 'never includes appointments from other organizations' do
      [admin, professional_user, secretary, client].each do |user|
        scope = described_class::Scope.new(user, Appointment).resolve
        expect(scope).not_to include(*other_org_appointments)
      end
    end
  end
end

# Integration test for authorization in requests
RSpec.describe 'API Authorization', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:other_org_user) { create(:user) }
  
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_for(user)}" } }
  let(:admin_headers) { { 'Authorization' => "Bearer #{generate_jwt_for(admin)}" } }
  
  describe 'cross-tenant access prevention' do
    let(:other_appointment) { create(:appointment, organization: other_org_user.organization) }
    
    it 'returns 403 when accessing resources from another organization' do
      get api_v1_appointment_path(other_appointment), headers: headers
      
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You are not authorized to perform this action')
      expect(json_response['code']).to eq('FORBIDDEN')
    end
    
    it 'returns 403 even for admins accessing other organizations' do
      other_org = create(:organization)
      
      get api_v1_organization_path(other_org), headers: admin_headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe 'role-based access control' do
    context 'organization management' do
      it 'allows admin to update organization' do
        patch api_v1_organization_path(organization), 
          params: { organization: { name: 'New Name' } },
          headers: admin_headers
        
        expect(response).to have_http_status(:ok)
      end
      
      it 'denies non-admin from updating organization' do
        patch api_v1_organization_path(organization), 
          params: { organization: { name: 'New Name' } },
          headers: headers
        
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'appointment state transitions' do
      let(:appointment) { create(:appointment, :pre_confirmed, organization: organization) }
      let(:secretary) { create(:user, :secretary, organization: organization) }
      let(:secretary_headers) { { 'Authorization' => "Bearer #{generate_jwt_for(secretary)}" } }
      
      it 'allows secretary to confirm appointments' do
        post confirm_api_v1_appointment_path(appointment), headers: secretary_headers
        
        expect(response).to have_http_status(:ok)
        expect(appointment.reload).to be_confirmed
      end
      
      it 'denies regular user from confirming appointments' do
        post confirm_api_v1_appointment_path(appointment), headers: headers
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'policy scoping' do
    let!(:visible_appointments) { create_list(:appointment, 2, organization: organization) }
    let!(:hidden_appointments) { create_list(:appointment, 3) }
    
    it 'only returns appointments from user\'s organization' do
      get api_v1_appointments_path, headers: headers
      
      expect(response).to have_http_status(:ok)
      returned_ids = json_response.map { |a| a['id'] }
      expect(returned_ids).to match_array(visible_appointments.map(&:id))
      expect(returned_ids).not_to include(*hidden_appointments.map(&:id))
    end
  end
  
  private
  
  def generate_jwt_for(user)
    # Mock JWT generation
    JWT.encode(
      {
        user_id: user.id,
        organization_id: user.organization_id,
        roles: user.roles.pluck(:name),
        exp: 1.hour.from_now.to_i
      },
      Rails.application.credentials.devise_jwt_secret_key
    )
  end
  
  def json_response
    JSON.parse(response.body)
  end
end