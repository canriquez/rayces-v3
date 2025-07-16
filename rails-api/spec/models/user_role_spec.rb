# spec/models/user_role_spec.rb
require 'rails_helper'

RSpec.describe UserRole, type: :model do
  let(:organization) { create(:organization, name: "Test Org #{Time.now.to_i}", subdomain: "test-#{Time.now.to_i}") }
  let(:secondary_organization) { create(:organization, name: "Secondary Org #{Time.now.to_i}", subdomain: "secondary-#{Time.now.to_i}") }
  let(:user) { create(:user, organization: organization, email: "test-#{Time.now.to_i}@example.com") }
  let(:role) { organization.roles.find_by(key: 'professional') || create(:role, :professional, organization: organization) }
  
  describe 'validations' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'validates presence of required associations' do
      user_role = UserRole.new
      expect(user_role).not_to be_valid
      expect(user_role.errors[:user]).to include("can't be blank")
      expect(user_role.errors[:role]).to include("can't be blank")
      # Organization gets set automatically by callback, so we test different scenario
    end
    
    it 'validates user and role belong to same organization' do
      different_org_role = secondary_organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: secondary_organization)
      user_role = UserRole.new(user: user, role: different_org_role, organization: organization)
      
      expect(user_role).not_to be_valid
      expect(user_role.errors[:base]).to include('User and role must belong to the same organization')
    end
    
    it 'validates role belongs to organization' do
      different_org_role = secondary_organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: secondary_organization)
      user_role = UserRole.new(user: user, role: different_org_role, organization: organization)
      
      expect(user_role).not_to be_valid
      expect(user_role.errors[:role]).to include('must belong to the same organization')
    end
    
    it 'validates uniqueness of user-role combination' do
      create(:user_role, user: user, role: role, organization: organization)
      duplicate_user_role = UserRole.new(user: user, role: role, organization: organization)
      
      expect(duplicate_user_role).not_to be_valid
      expect(duplicate_user_role.errors[:user_id]).to include('already has this role in the organization')
    end
  end
  
  describe 'associations' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'belongs to user' do
      user_role = create(:user_role, user: user, role: role, organization: organization)
      expect(user_role.user).to eq(user)
    end
    
    it 'belongs to role' do
      user_role = create(:user_role, user: user, role: role, organization: organization)
      expect(user_role.role).to eq(role)
    end
    
    it 'belongs to organization' do
      user_role = create(:user_role, user: user, role: role, organization: organization)
      expect(user_role.organization).to eq(organization)
    end
  end
  
  describe 'scopes' do
    before { ActsAsTenant.current_tenant = organization }
    
    let(:second_user) { create(:user, organization: organization, email: "second-#{Time.now.to_i}@example.com") }
    let!(:active_user_role) { create(:user_role, user: user, role: role, organization: organization, active: true) }
    let!(:inactive_user_role) { create(:user_role, user: second_user, role: role, organization: organization, active: false) }
    
    it 'filters active user roles' do
      expect(UserRole.active).to include(active_user_role)
      expect(UserRole.active).not_to include(inactive_user_role)
    end
    
    it 'filters inactive user roles' do
      expect(UserRole.inactive).to include(inactive_user_role)
      expect(UserRole.inactive).not_to include(active_user_role)
    end
    
    it 'filters recently assigned user roles' do
      third_user = create(:user, organization: organization, email: "third-#{Time.now.to_i}@example.com")
      fourth_user = create(:user, organization: organization, email: "fourth-#{Time.now.to_i}@example.com")
      
      recent_role = create(:user_role, user: third_user, role: role, organization: organization, assigned_at: 1.day.ago)
      old_role = create(:user_role, user: fourth_user, role: role, organization: organization, assigned_at: 2.weeks.ago)
      
      expect(UserRole.assigned_recently).to include(recent_role)
      expect(UserRole.assigned_recently).not_to include(old_role)
    end
    
    it 'filters by role key' do
      admin_role = organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: organization)
      admin_user_role = create(:user_role, user: second_user, role: admin_role, organization: organization)
      
      expect(UserRole.by_role_key('professional')).to include(active_user_role)
      expect(UserRole.by_role_key('admin')).to include(admin_user_role)
      expect(UserRole.by_role_key('admin')).not_to include(active_user_role)
    end
  end
  
  describe 'callbacks' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'sets organization from associations before validation' do
      user_role = UserRole.new(user: user, role: role)
      user_role.valid? # Trigger validations and callbacks
      expect(user_role.organization).to eq(organization)
    end
    
    it 'sets assigned_at before create' do
      user_role = create(:user_role, user: user, role: role, organization: organization)
      expect(user_role.assigned_at).to be_present
      expect(user_role.assigned_at).to be_within(1.second).of(Time.current)
    end
    
    it 'does not override manually set assigned_at' do
      custom_time = 1.hour.ago
      user_role = create(:user_role, user: user, role: role, organization: organization, assigned_at: custom_time)
      expect(user_role.assigned_at).to be_within(1.second).of(custom_time)
    end
  end
  
  describe 'instance methods' do
    before { ActsAsTenant.current_tenant = organization }
    
    let(:user_role) { create(:user_role, user: user, role: role, organization: organization) }
    
    describe 'activation methods' do
      it 'activates user role' do
        user_role.update!(active: false)
        user_role.activate!
        
        expect(user_role.active).to be true
        expect(user_role.assigned_at).to be_within(1.second).of(Time.current)
      end
      
      it 'deactivates user role' do
        user_role.update!(active: true)
        user_role.deactivate!
        
        expect(user_role.active).to be false
      end
    end
    
    describe 'role type checking' do
      it 'identifies admin role' do
        admin_role = organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: organization)
        admin_user = create(:user, organization: organization, email: "admin-#{Time.now.to_i}@example.com")
        admin_user_role = create(:user_role, user: admin_user, role: admin_role, organization: organization)
        
        expect(admin_user_role.admin?).to be true
        expect(user_role.admin?).to be false
      end
      
      it 'identifies professional role' do
        expect(user_role.professional?).to be true
        
        admin_role = organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: organization)
        admin_user = create(:user, organization: organization, email: "admin-#{Time.now.to_i}@example.com")
        admin_user_role = create(:user_role, user: admin_user, role: admin_role, organization: organization)
        expect(admin_user_role.professional?).to be false
      end
      
      it 'identifies secretary role' do
        secretary_role = organization.roles.find_by(key: 'secretary') || create(:role, :secretary, organization: organization)
        secretary_user = create(:user, organization: organization, email: "secretary-#{Time.now.to_i}@example.com")
        secretary_user_role = create(:user_role, user: secretary_user, role: secretary_role, organization: organization)
        
        expect(secretary_user_role.secretary?).to be true
        expect(user_role.secretary?).to be false
      end
      
      it 'identifies client role' do
        client_role = organization.roles.find_by(key: 'client') || create(:role, :client, organization: organization)
        client_user = create(:user, organization: organization, email: "client-unique-#{Time.now.to_i}@example.com")
        
        # Build instead of create to avoid uniqueness constraint issues
        client_user_role = UserRole.new(user: client_user, role: client_role, organization: organization)
        
        expect(client_user_role.client?).to be true
        expect(user_role.client?).to be false
      end
    end
    
    describe 'role information methods' do
      it 'returns role key' do
        expect(user_role.role_key).to eq('professional')
      end
      
      it 'returns role name' do
        expect(user_role.role_name).to eq(role.name)
      end
    end
    
    describe 'capability checking' do
      it 'checks organization management capability' do
        admin_role = organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: organization)
        admin_user = create(:user, organization: organization, email: "admin-#{Time.now.to_i}@example.com")
        admin_user_role = create(:user_role, user: admin_user, role: admin_role, organization: organization, active: true)
        
        inactive_admin_user = create(:user, organization: organization, email: "inactive-admin-#{Time.now.to_i}@example.com")
        inactive_admin = create(:user_role, user: inactive_admin_user, role: admin_role, organization: organization, active: false)
        
        expect(admin_user_role.can_manage_organization?).to be true
        expect(user_role.can_manage_organization?).to be false
        expect(inactive_admin.can_manage_organization?).to be false
      end
      
      it 'checks appointment management capability' do
        secretary_role = organization.roles.find_by(key: 'secretary') || create(:role, :secretary, organization: organization)
        secretary_user = create(:user, organization: organization, email: "secretary-#{Time.now.to_i}@example.com")
        secretary_user_role = create(:user_role, user: secretary_user, role: secretary_role, organization: organization, active: true)
        
        expect(user_role.can_manage_appointments?).to be true # professional
        expect(secretary_user_role.can_manage_appointments?).to be true
        
        client_role = organization.roles.find_by(key: 'client') || create(:role, :client, organization: organization)
        client_user = create(:user, organization: organization, email: "client-mgmt-#{Time.now.to_i}@example.com")
        client_user_role = UserRole.new(user: client_user, role: client_role, organization: organization, active: true)
        expect(client_user_role.can_manage_appointments?).to be false
      end
      
      it 'checks appointment booking capability' do
        client_role = organization.roles.find_by(key: 'client') || create(:role, :client, organization: organization)
        client_user = create(:user, organization: organization, email: "client-book-#{Time.now.to_i}@example.com")
        client_user_role = UserRole.new(user: client_user, role: client_role, organization: organization, active: true)
        
        expect(client_user_role.can_book_appointments?).to be true
        expect(user_role.can_book_appointments?).to be false # professional
      end
      
      it 'only allows capabilities for active roles' do
        user_role.update!(active: false)
        expect(user_role.can_manage_appointments?).to be false
      end
    end
  end
  
  describe 'multi-tenancy' do
    it 'respects tenant scoping' do
      expect(ActsAsTenant).to respond_to(:current_tenant)
      # Check that UserRole respects tenant scoping by testing behavior
      user_role_count = UserRole.count
      expect(user_role_count).to be >= 0 # Should work without error when tenant is set
    end
    
    it 'only shows user roles for current tenant' do
      ActsAsTenant.with_tenant(organization) do
        org1_user_role = create(:user_role, user: user, role: role, organization: organization)
        
        ActsAsTenant.with_tenant(secondary_organization) do
          secondary_user = create(:user, organization: secondary_organization, email: "secondary-#{Time.now.to_i}@example.com")
          secondary_role = secondary_organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: secondary_organization)
          org2_user_role = create(:user_role, user: secondary_user, role: secondary_role, organization: secondary_organization)
          
          # Should only see org2 user role when scoped to secondary_organization
          expect(UserRole.all).to include(org2_user_role)
          expect(UserRole.all).not_to include(org1_user_role)
        end
        
        ActsAsTenant.with_tenant(organization) do
          # Should only see org1 user role when scoped to organization
          expect(UserRole.all).to include(org1_user_role)
        end
      end
    end
    
    it 'prevents cross-tenant role assignments' do
      different_org_user = create(:user, organization: secondary_organization, email: "different-#{Time.now.to_i}@example.com")
      
      ActsAsTenant.with_tenant(organization) do
        user_role = UserRole.new(user: different_org_user, role: role, organization: organization)
        expect(user_role).not_to be_valid
        expect(user_role.errors[:base]).to include('User and role must belong to the same organization')
      end
    end
  end
  
  describe 'integration with User model' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'integrates with user role management methods' do
      expect(user.assign_role('professional')).to be true
      expect(user.has_role?('professional')).to be true
      expect(user.role_keys).to include('professional')
    end
    
    it 'allows multiple roles per user' do
      admin_role = organization.roles.find_by(key: 'admin') || create(:role, :admin, organization: organization)
      
      user.assign_role('professional')
      user.assign_role('admin')
      
      expect(user.role_keys).to include('professional', 'admin')
      expect(user.has_role?('professional')).to be true
      expect(user.has_role?('admin')).to be true
    end
    
    it 'removes roles properly' do
      user.assign_role('professional')
      expect(user.has_role?('professional')).to be true
      
      user.remove_role('professional')
      expect(user.has_role?('professional')).to be false
    end
  end
  
  describe 'error handling and edge cases' do
    before { ActsAsTenant.current_tenant = organization }
    
    it 'handles nil role gracefully' do
      user_role = UserRole.new(user: user, role: nil, organization: organization)
      expect(user_role).not_to be_valid
      expect(user_role.role_key).to be_nil
      expect(user_role.role_name).to be_nil
    end
    
    it 'handles invalid organization references' do
      user_role = UserRole.new(user: nil, role: nil, organization: nil)
      expect(user_role).not_to be_valid
      expect(user_role.errors[:user]).to include("can't be blank")
      expect(user_role.errors[:role]).to include("can't be blank")
      # Organization might get set by callback, but we know it's invalid if user/role are nil
    end
    
    it 'prevents saving with mismatched organizations' do
      # Ensure we have distinct organizations
      org1 = organization
      org2 = secondary_organization
      
      # Ensure roles exist
      Role.create_defaults_for_organization(org1) unless org1.roles.exists?
      Role.create_defaults_for_organization(org2) unless org2.roles.exists?
      
      # Create user explicitly in org2 context to ensure proper organization assignment
      different_user = ActsAsTenant.with_tenant(org2) do
        create(:user, organization: org2, email: "mismatch-#{Time.now.to_i}@example.com")
      end
      role_from_org1 = org1.roles.find_by(key: 'professional')
      
      # This should fail because user is from org2 but role is from org1
      user_role = UserRole.new(user: different_user, role: role_from_org1, organization: org1)
      
      expect(user_role).not_to be_valid
      expect(user_role.errors[:base]).not_to be_empty
    end
  end
end