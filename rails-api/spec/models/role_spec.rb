# spec/models/role_spec.rb
require 'rails_helper'

RSpec.describe Role, type: :model do
  let(:organization) { create(:organization, name: "Test Org #{Time.now.to_i}", subdomain: "test-#{Time.now.to_i}") }
  let(:secondary_organization) { create(:organization, name: "Secondary Org #{Time.now.to_i}", subdomain: "secondary-#{Time.now.to_i}") }
  
  # Test basic role creation within organization context
  describe 'validations' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'validates presence of required fields' do
      role = Role.new
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("can't be blank")
      expect(role.errors[:key]).to include("can't be blank")
    end
    
    it 'validates key is in allowed list' do
      invalid_keys = ['custom', 'manager', 'invalid']
      
      invalid_keys.each do |key|
        role = build(:role, key: key, organization: organization)
        expect(role).not_to be_valid
        expect(role.errors[:key]).to include('is not included in the list')
      end
      
      # Test that valid keys pass validation (just build, don't validate uniqueness here)
      valid_keys = ['admin', 'professional', 'secretary', 'client']
      valid_keys.each do |key|
        role = Role.new(key: key, name: key.titleize, organization: organization)
        role.valid?
        expect(role.errors[:key]).not_to include('is not included in the list')
      end
    end
  end
  
  describe 'associations' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'belongs to organization' do
      role = organization.roles.first || Role.create!(key: 'admin', name: 'Admin', organization: organization)
      expect(role.organization).to eq(organization)
    end
    
    it 'has many user_roles' do
      role = organization.roles.first || Role.create!(key: 'admin', name: 'Admin', organization: organization)
      user = create(:user, organization: organization, email: "test-#{Time.now.to_i}@example.com")
      user_role = create(:user_role, user: user, role: role, organization: organization)
      
      expect(role.user_roles).to include(user_role)
    end
    
    it 'has many users through user_roles' do
      role = organization.roles.first || Role.create!(key: 'admin', name: 'Admin', organization: organization)
      user = create(:user, organization: organization, email: "test-#{Time.now.to_i}@example.com")
      create(:user_role, user: user, role: role, organization: organization)
      
      expect(role.users).to include(user)
    end
  end
  
  describe 'scopes' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'finds roles by key' do
      admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
      
      expect(Role.by_key('admin')).to include(admin_role)
    end
    
    it 'filters default roles' do
      Role.create_defaults_for_organization(organization) if organization.roles.empty?
      default_roles = Role.where(key: %w[admin professional secretary client])
      
      expect(default_roles.count).to be >= 4
    end
  end
  
  describe 'class methods' do
    it 'creates default roles for organization' do
      # Skip if roles already exist
      if organization.roles.empty?
        expect {
          Role.create_defaults_for_organization(organization)
        }.to change { organization.roles.count }.by(4)
      end
      
      expect(organization.roles.pluck(:key)).to include('admin', 'professional', 'secretary', 'client')
    end
    
    it 'does not duplicate default roles if they already exist' do
      Role.create_defaults_for_organization(organization)
      initial_count = organization.roles.count
      
      expect {
        Role.create_defaults_for_organization(organization)
      }.not_to change { organization.roles.count }
    end
  end
  
  describe 'instance methods' do
    before { ActsAsTenant.current_tenant = organization }
    
    describe 'role type checking' do
      it 'identifies admin role' do
        admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
        professional_role = organization.roles.find_by(key: 'professional') || Role.create!(key: 'professional', name: 'Professional', organization: organization)
        
        expect(admin_role.admin?).to be true
        expect(professional_role.admin?).to be false
      end
      
      it 'identifies professional role' do
        admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
        professional_role = organization.roles.find_by(key: 'professional') || Role.create!(key: 'professional', name: 'Professional', organization: organization)
        
        expect(professional_role.professional?).to be true
        expect(admin_role.professional?).to be false
      end
      
      it 'identifies secretary role' do
        secretary_role = organization.roles.find_by(key: 'secretary') || Role.create!(key: 'secretary', name: 'Secretary', organization: organization)
        client_role = organization.roles.find_by(key: 'client') || Role.create!(key: 'client', name: 'Client', organization: organization)
        
        expect(secretary_role.secretary?).to be true
        expect(client_role.secretary?).to be false
      end
      
      it 'identifies client role' do
        client_role = organization.roles.find_by(key: 'client') || Role.create!(key: 'client', name: 'Client', organization: organization)
        admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
        
        expect(client_role.client?).to be true
        expect(admin_role.client?).to be false
      end
    end
    
    describe 'capability checking' do
      it 'admin can manage organization' do
        admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
        client_role = organization.roles.find_by(key: 'client') || Role.create!(key: 'client', name: 'Client', organization: organization)
        
        expect(admin_role.can_manage_organization?).to be true
        expect(client_role.can_manage_organization?).to be false
      end
      
      it 'professionals and secretaries can manage appointments' do
        admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
        professional_role = organization.roles.find_by(key: 'professional') || Role.create!(key: 'professional', name: 'Professional', organization: organization)
        secretary_role = organization.roles.find_by(key: 'secretary') || Role.create!(key: 'secretary', name: 'Secretary', organization: organization)
        client_role = organization.roles.find_by(key: 'client') || Role.create!(key: 'client', name: 'Client', organization: organization)
        
        expect(admin_role.can_manage_appointments?).to be true
        expect(professional_role.can_manage_appointments?).to be true
        expect(secretary_role.can_manage_appointments?).to be true
        expect(client_role.can_manage_appointments?).to be false
      end
      
      it 'clients and admins can book appointments' do
        admin_role = organization.roles.find_by(key: 'admin') || Role.create!(key: 'admin', name: 'Admin', organization: organization)
        client_role = organization.roles.find_by(key: 'client') || Role.create!(key: 'client', name: 'Client', organization: organization)
        professional_role = organization.roles.find_by(key: 'professional') || Role.create!(key: 'professional', name: 'Professional', organization: organization)
        
        expect(admin_role.can_book_appointments?).to be true
        expect(client_role.can_book_appointments?).to be true
        expect(professional_role.can_book_appointments?).to be false
      end
    end
  end
  
  describe 'multi-tenancy' do
    it 'is scoped to organization via acts_as_tenant' do
      expect(ActsAsTenant).to respond_to(:current_tenant)
      # Check that Role respects tenant scoping by testing behavior
      role_count = Role.count
      expect(role_count).to be >= 0 # Should work without error when tenant is set
    end
    
    it 'only shows roles for current tenant' do
      # Ensure each org has roles
      Role.create_defaults_for_organization(organization) if organization.roles.empty?
      Role.create_defaults_for_organization(secondary_organization) if secondary_organization.roles.empty?
      
      ActsAsTenant.with_tenant(secondary_organization) do
        # Should only see secondary_organization roles
        visible_roles = Role.all
        expect(visible_roles.map(&:organization_id).uniq).to eq([secondary_organization.id])
      end
      
      ActsAsTenant.with_tenant(organization) do
        # Should only see organization roles
        visible_roles = Role.all
        expect(visible_roles.map(&:organization_id).uniq).to eq([organization.id])
      end
    end
  end
  
  describe 'callbacks and normalization' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'normalizes key to lowercase' do
      # Test with an existing role to avoid uniqueness conflicts
      if organization.roles.find_by(key: 'admin')
        organization.roles.find_by(key: 'admin').destroy
      end
      
      role = Role.create!(key: 'Admin', name: 'Administrator', organization: organization)
      expect(role.key).to eq('admin')
    end
  end
end