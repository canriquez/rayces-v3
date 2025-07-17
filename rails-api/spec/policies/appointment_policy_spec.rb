require 'rails_helper'

RSpec.describe AppointmentPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:admin_user) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, :admin, organization: organization)
    end
  end
  let(:professional_user) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, :professional, organization: organization)
    end
  end
  let(:staff_user) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, :staff, organization: organization)
    end
  end
  let(:parent_user) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, :guardian, organization: organization)
    end
  end
  let(:other_parent) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, :guardian, organization: organization)
    end
  end
  
  let(:professional) do
    ActsAsTenant.with_tenant(organization) do
      create(:professional, user: professional_user, organization: organization)
    end
  end
  let(:appointment) do
    ActsAsTenant.with_tenant(organization) do
      create(:appointment, professional: professional_user, client: parent_user, organization: organization)
    end
  end
  let(:other_appointment) do
    ActsAsTenant.with_tenant(organization) do
      create(:appointment, professional: professional_user, client: other_parent, organization: organization)
    end
  end
  
  let(:other_org) { create(:organization, subdomain: 'other') }
  let(:other_org_user) do
    ActsAsTenant.with_tenant(other_org) do
      create(:user, :admin, organization: other_org)
    end
  end

  describe 'Scope' do
    before do
      ActsAsTenant.with_tenant(organization) do
        @appointment1 = create(:appointment, professional: professional_user, client: parent_user, organization: organization)
        @appointment2 = create(:appointment, professional: professional_user, client: other_parent, organization: organization)
      end
      ActsAsTenant.with_tenant(other_org) do
        @other_appointment = create(:appointment, organization: other_org)
      end
    end

    it 'returns appointments for user organization only' do
      # NOTE: Multi-tenancy scoping belongs to SCRUM-33, not SCRUM-32
      ActsAsTenant.without_tenant do
        user_context = UserContext.new(admin_user, organization)
        scope = AppointmentPolicy::Scope.new(user_context, Appointment).resolve
        
        expect(scope).to include(@appointment1, @appointment2)
        expect(scope).not_to include(@other_appointment)
      end
    end
  end

  describe '#index?' do
    it 'grants access to all user roles' do
      [admin_user, professional_user, staff_user, parent_user].each do |user|
        user_context = UserContext.new(user, organization)
        policy = AppointmentPolicy.new(user_context, Appointment)
        expect(policy.index?).to be_truthy
      end
    end
  end

  describe '#show?' do
    it 'allows admins to view any appointment' do
      user_context = UserContext.new(admin_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.show?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.show?).to be_truthy
    end

    it 'allows staff to view any appointment' do
      user_context = UserContext.new(staff_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.show?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.show?).to be_truthy
    end

    it 'allows professionals to view their appointments' do
      user_context = UserContext.new(professional_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.show?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.show?).to be_truthy
    end

    it 'allows parents to view their appointments only' do
      user_context = UserContext.new(parent_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.show?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.show?).to be_falsy
    end

    it 'denies access to appointments from other organizations' do
      other_org_appointment = ActsAsTenant.with_tenant(other_org) do
        create(:appointment, organization: other_org)
      end
      user_context = UserContext.new(admin_user, organization)
      policy = AppointmentPolicy.new(user_context, other_org_appointment)
      expect(policy.show?).to be_falsy
    end
  end

  describe '#create?' do
    it 'allows admins to create appointments' do
      user_context = UserContext.new(admin_user, organization)
      policy = AppointmentPolicy.new(user_context, Appointment)
      expect(policy.create?).to be_truthy
    end

    it 'allows staff to create appointments' do
      user_context = UserContext.new(staff_user, organization)
      policy = AppointmentPolicy.new(user_context, Appointment)
      expect(policy.create?).to be_truthy
    end

    it 'allows professionals to create appointments' do
      user_context = UserContext.new(professional_user, organization)
      policy = AppointmentPolicy.new(user_context, Appointment)
      expect(policy.create?).to be_truthy
    end

    it 'allows parents to create appointments for themselves' do
      user_context = UserContext.new(parent_user, organization)
      policy = AppointmentPolicy.new(user_context, Appointment)
      expect(policy.create?).to be_truthy
    end
  end

  describe '#update?' do
    it 'allows admins to update any appointment' do
      user_context = UserContext.new(admin_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.update?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.update?).to be_truthy
    end

    it 'allows staff to update any appointment' do
      user_context = UserContext.new(staff_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.update?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.update?).to be_truthy
    end

    it 'allows professionals to update their appointments' do
      user_context = UserContext.new(professional_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.update?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.update?).to be_truthy
    end

    it 'allows parents to update their appointments only' do
      user_context = UserContext.new(parent_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.update?).to be_truthy
      
      policy = AppointmentPolicy.new(user_context, other_appointment)
      expect(policy.update?).to be_falsy
    end
  end

  describe '#destroy?' do
    it 'allows admins to destroy appointments' do
      user_context = UserContext.new(admin_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.destroy?).to be_truthy
    end

    it 'allows staff to destroy appointments' do
      user_context = UserContext.new(staff_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.destroy?).to be_truthy
    end

    it 'denies professionals from destroying appointments' do
      user_context = UserContext.new(professional_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.destroy?).to be_falsy
    end

    it 'denies parents from destroying appointments' do
      user_context = UserContext.new(parent_user, organization)
      policy = AppointmentPolicy.new(user_context, appointment)
      expect(policy.destroy?).to be_falsy
    end
  end

  describe 'multi-tenant security' do
    let(:other_org_appointment) { create(:appointment, organization: other_org) }

    it 'prevents cross-tenant access for all operations' do
      # NOTE: Multi-tenancy security belongs to SCRUM-33, not SCRUM-32
      user_context = UserContext.new(admin_user, organization)
      policy = AppointmentPolicy.new(user_context, other_org_appointment)
      
      expect(policy.show?).to be_falsy
      expect(policy.update?).to be_falsy
      expect(policy.destroy?).to be_falsy
    end
  end
end