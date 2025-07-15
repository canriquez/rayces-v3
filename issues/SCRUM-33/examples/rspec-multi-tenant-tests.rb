# RSpec Multi-tenant Testing Examples
# This example shows comprehensive testing strategies for multi-tenant Rails applications
# Based on acts_as_tenant testing best practices

# spec/support/acts_as_tenant.rb
# Configure acts_as_tenant for testing
RSpec.configure do |config|
  config.before(:suite) do
    # Create default organizations for testing
    DatabaseCleaner.clean_with(:truncation)
    
    # Create test organizations
    $default_organization = FactoryBot.create(:organization, 
      name: 'Test Organization',
      subdomain: 'test-org'
    )
    
    $secondary_organization = FactoryBot.create(:organization,
      name: 'Secondary Organization', 
      subdomain: 'secondary-org'
    )
  end
  
  config.before(:each) do |example|
    # Set up tenant based on test type
    if example.metadata[:type] == :request
      # For request specs, use test_tenant
      ActsAsTenant.test_tenant = $default_organization
    else
      # For other specs, use current_tenant
      ActsAsTenant.current_tenant = $default_organization
    end
  end
  
  config.after(:each) do
    # Clear tenant context after each test
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
  end
end

# spec/models/organization_spec.rb
require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'validations' do
    subject { build(:organization) }
    
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain).case_insensitive }
    it { should validate_uniqueness_of(:domain).case_insensitive.allow_blank }
    
    it 'validates subdomain format' do
      invalid_subdomains = ['Test Org', 'test.org', 'test_org', 'TEST', '123-']
      invalid_subdomains.each do |subdomain|
        org = build(:organization, subdomain: subdomain)
        expect(org).not_to be_valid
        expect(org.errors[:subdomain]).to include('only lowercase letters, numbers, and hyphens')
      end
      
      valid_subdomains = ['test-org', 'org123', 'my-company-123']
      valid_subdomains.each do |subdomain|
        org = build(:organization, subdomain: subdomain)
        expect(org).to be_valid
      end
    end
  end
  
  describe 'associations' do
    it { should have_many(:users).dependent(:restrict_with_error) }
    it { should have_many(:posts).dependent(:restrict_with_error) }
    it { should have_many(:likes).dependent(:restrict_with_error) }
    it { should have_many(:roles).dependent(:restrict_with_error) }
  end
  
  describe 'callbacks' do
    describe '#normalize_subdomain' do
      it 'converts subdomain to lowercase' do
        org = create(:organization, subdomain: 'MyOrg')
        expect(org.subdomain).to eq('myorg')
      end
      
      it 'strips whitespace from subdomain' do
        org = create(:organization, subdomain: ' test-org ')
        expect(org.subdomain).to eq('test-org')
      end
    end
    
    describe '#setup_default_roles' do
      it 'creates default roles after organization creation' do
        org = create(:organization)
        
        expect(org.roles.count).to eq(4)
        expect(org.roles.pluck(:key)).to contain_exactly('admin', 'professional', 'secretary', 'client')
      end
    end
  end
  
  describe 'class methods' do
    describe '.find_by_domain_or_subdomain' do
      let!(:org_with_domain) { create(:organization, domain: 'custom.com', subdomain: 'custom') }
      let!(:org_with_subdomain) { create(:organization, subdomain: 'test-app') }
      
      it 'finds by custom domain first' do
        result = Organization.find_by_domain_or_subdomain('custom.com')
        expect(result).to eq(org_with_domain)
      end
      
      it 'finds by subdomain if no custom domain' do
        result = Organization.find_by_domain_or_subdomain('test-app.example.com')
        expect(result).to eq(org_with_subdomain)
      end
      
      it 'returns nil for inactive organizations' do
        org_with_domain.update!(active: false)
        result = Organization.find_by_domain_or_subdomain('custom.com')
        expect(result).to be_nil
      end
    end
  end
end

# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  
  before do
    ActsAsTenant.current_tenant = organization
  end
  
  describe 'multi-tenancy' do
    it 'belongs to an organization' do
      user = create(:user, organization: organization)
      expect(user.organization).to eq(organization)
    end
    
    it 'validates uniqueness of email within organization scope' do
      create(:user, email: 'test@example.com', organization: organization)
      
      # Same email in same organization should fail
      duplicate = build(:user, email: 'test@example.com', organization: organization)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been taken')
      
      # Same email in different organization should succeed
      ActsAsTenant.with_tenant(other_organization) do
        different_org_user = build(:user, email: 'test@example.com', organization: other_organization)
        expect(different_org_user).to be_valid
      end
    end
    
    it 'is scoped to current tenant' do
      user1 = create(:user, organization: organization)
      
      ActsAsTenant.with_tenant(other_organization) do
        user2 = create(:user, organization: other_organization)
        
        # Users from other organization should not be visible
        expect(User.all).not_to include(user1)
        expect(User.all).to include(user2)
      end
      
      # Back in original tenant context
      expect(User.all).to include(user1)
    end
  end
  
  describe 'role management' do
    let(:user) { create(:user, organization: organization) }
    let(:admin_role) { organization.roles.find_by(key: 'admin') }
    let(:client_role) { organization.roles.find_by(key: 'client') }
    
    describe '#assign_role' do
      it 'assigns a role to the user' do
        expect(user.assign_role('admin')).to be_truthy
        expect(user.has_role?('admin')).to be true
      end
      
      it 'does not duplicate role assignments' do
        user.assign_role('admin')
        user.assign_role('admin')
        
        expect(user.roles.where(key: 'admin').count).to eq(1)
      end
      
      it 'returns false for non-existent roles' do
        expect(user.assign_role('invalid_role')).to be false
      end
    end
    
    describe '#remove_role' do
      before { user.assign_role('admin') }
      
      it 'removes the role from the user' do
        user.remove_role('admin')
        expect(user.has_role?('admin')).to be false
      end
    end
    
    describe '#has_role?' do
      it 'returns true when user has the role' do
        user.assign_role('professional')
        expect(user.has_role?('professional')).to be true
      end
      
      it 'returns false when user does not have the role' do
        expect(user.has_role?('secretary')).to be false
      end
    end
  end
  
  describe 'callbacks' do
    it 'assigns default client role on creation' do
      user = create(:user, organization: organization)
      expect(user.has_role?('client')).to be true
    end
    
    it 'creates client profile after creation' do
      user = create(:user, organization: organization)
      expect(user.client_profile).to be_present
      expect(user.client_profile.organization).to eq(organization)
    end
  end
  
  describe 'tenant access control' do
    let(:user) { create(:user, organization: organization) }
    
    it 'can access its own organization' do
      expect(user.can_access_organization?(organization)).to be true
    end
    
    it 'cannot access other organizations' do
      expect(user.can_access_organization?(other_organization)).to be false
    end
    
    it 'super admin can access any organization' do
      user.update!(super_admin: true)
      expect(user.can_access_organization?(other_organization)).to be true
    end
  end
end

# spec/requests/api/v1/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:auth_headers) { generate_auth_headers(user, organization) }
  let(:admin_headers) { generate_auth_headers(admin, organization) }
  
  describe 'GET /api/v1/users' do
    let!(:org_users) { create_list(:user, 3, organization: organization) }
    let!(:other_org_users) { create_list(:user, 2, organization: other_organization) }
    
    context 'with valid subdomain' do
      it 'returns users from the organization' do
        get '/api/v1/users', 
            headers: auth_headers.merge('X-Organization-Subdomain' => organization.subdomain)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['users'].size).to eq(4) # 3 created + 1 auth user
        
        returned_ids = json['users'].map { |u| u['id'] }
        expect(returned_ids).to include(user.id)
        expect(returned_ids).not_to include(other_org_users.first.id)
      end
    end
    
    context 'with invalid subdomain' do
      it 'returns not found' do
        get '/api/v1/users',
            headers: auth_headers.merge('X-Organization-Subdomain' => 'invalid-subdomain')
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Organization not found or inactive')
      end
    end
    
    context 'without subdomain' do
      it 'uses user organization as tenant' do
        get '/api/v1/users', headers: auth_headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        # Should still only see users from auth user's organization
        returned_org_ids = json['users'].map { |u| u['organization_id'] }.uniq
        expect(returned_org_ids).to eq([organization.id])
      end
    end
    
    context 'cross-tenant access attempt' do
      it 'prevents access to other organization data' do
        # Try to access other organization's data
        get '/api/v1/users',
            headers: auth_headers.merge('X-Organization-Subdomain' => other_organization.subdomain)
        
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Not authorized to access this organization')
      end
    end
  end
  
  describe 'POST /api/v1/users' do
    context 'as admin' do
      it 'creates user in the current organization' do
        user_params = {
          user: {
            email: 'newuser@example.com',
            first_name: 'New',
            last_name: 'User',
            password: 'password123'
          }
        }
        
        expect {
          post '/api/v1/users',
               params: user_params,
               headers: admin_headers.merge('X-Organization-Subdomain' => organization.subdomain)
        }.to change { User.count }.by(1)
        
        expect(response).to have_http_status(:created)
        
        new_user = User.last
        expect(new_user.organization).to eq(organization)
        expect(new_user.email).to eq('newuser@example.com')
      end
      
      it 'cannot create user in different organization' do
        user_params = {
          user: {
            email: 'hacker@example.com',
            organization_id: other_organization.id # Trying to set different org
          }
        }
        
        post '/api/v1/users',
             params: user_params,
             headers: admin_headers
        
        # User should still be created in admin's organization
        new_user = User.find_by(email: 'hacker@example.com')
        expect(new_user.organization).to eq(organization)
        expect(new_user.organization).not_to eq(other_organization)
      end
    end
  end
  
  # Helper method to generate auth headers
  def generate_auth_headers(user, organization)
    token = JWT.encode(
      { 
        user_id: user.id, 
        organization_id: organization.id,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.credentials.secret_key_base,
      'HS256'
    )
    
    { 'Authorization' => "Bearer #{token}" }
  end
end

# spec/models/appointment_spec.rb
require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:client) { create(:user, :client, organization: organization) }
  let(:professional) { create(:user, :professional, organization: organization) }
  let(:service) { create(:service, organization: organization) }
  
  before do
    ActsAsTenant.current_tenant = organization
  end
  
  describe 'multi-tenancy' do
    let(:appointment) { create(:appointment, organization: organization) }
    
    it 'is scoped to organization' do
      other_appointment = nil
      
      ActsAsTenant.with_tenant(other_organization) do
        other_appointment = create(:appointment, organization: other_organization)
      end
      
      expect(Appointment.all).to include(appointment)
      expect(Appointment.all).not_to include(other_appointment)
    end
    
    it 'validates uniqueness of external_id within tenant' do
      create(:appointment, external_id: 'APP-001', organization: organization)
      
      # Same external_id in same organization should fail
      duplicate = build(:appointment, external_id: 'APP-001', organization: organization)
      expect(duplicate).not_to be_valid
      
      # Same external_id in different organization should succeed
      ActsAsTenant.with_tenant(other_organization) do
        different_org_appointment = build(:appointment, 
          external_id: 'APP-001', 
          organization: other_organization
        )
        expect(different_org_appointment).to be_valid
      end
    end
  end
  
  describe 'state transitions' do
    let(:appointment) { create(:appointment, :draft, organization: organization) }
    
    describe 'pre_confirm event' do
      it 'transitions from draft to pre_confirmed' do
        expect(appointment).to transition_from(:draft).to(:pre_confirmed).on_event(:pre_confirm)
      end
      
      it 'sets expiration time' do
        appointment.pre_confirm!
        expect(appointment.expiration_time).to be_within(1.minute).of(24.hours.from_now)
      end
    end
    
    describe 'confirm event' do
      it 'charges credits from client' do
        appointment.pre_confirm!
        
        expect {
          appointment.confirm!
        }.to change { appointment.client.credit_balance }.by(-service.credit_cost)
      end
      
      it 'creates credit transaction' do
        expect {
          appointment.confirm!
        }.to change { CreditTransaction.count }.by(1)
        
        transaction = CreditTransaction.last
        expect(transaction.user).to eq(appointment.client)
        expect(transaction.organization).to eq(organization)
        expect(transaction.transaction_type).to eq('appointment_charge')
      end
    end
    
    describe 'cancel event' do
      context 'when appointment is confirmed' do
        before { appointment.confirm! }
        
        it 'refunds credits' do
          expect {
            appointment.cancel!
          }.to change { appointment.client.credit_balance }.by(service.credit_cost)
        end
      end
    end
  end
  
  describe 'overlapping appointments validation' do
    let!(:existing_appointment) do
      create(:appointment,
        professional_profile: professional.professional_profile,
        start_time: 1.day.from_now,
        end_time: 1.day.from_now + 1.hour,
        status: 'confirmed'
      )
    end
    
    it 'prevents overlapping appointments for same professional' do
      overlapping = build(:appointment,
        professional_profile: professional.professional_profile,
        start_time: 1.day.from_now + 30.minutes,
        end_time: 1.day.from_now + 90.minutes
      )
      
      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:start_time]).to include('conflicts with another appointment')
    end
    
    it 'allows non-overlapping appointments' do
      non_overlapping = build(:appointment,
        professional_profile: professional.professional_profile,
        start_time: 1.day.from_now + 2.hours,
        end_time: 1.day.from_now + 3.hours
      )
      
      expect(non_overlapping).to be_valid
    end
  end
end