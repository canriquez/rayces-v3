require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
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
  let(:other_org) { create(:organization, subdomain: 'other') }
  let(:other_user) do
    ActsAsTenant.with_tenant(other_org) do
      create(:user, :admin, organization: other_org)
    end
  end

  describe 'Scope' do
    before do
      ActsAsTenant.with_tenant(organization) do
        @user1 = create(:user, organization: organization)
        @user2 = create(:user, organization: organization)
      end
      ActsAsTenant.with_tenant(other_org) do
        @other_user = create(:user, organization: other_org)
      end
    end

    it 'returns only users from the same organization' do
      # NOTE: Multi-tenancy scoping belongs to SCRUM-33, not SCRUM-32
      ActsAsTenant.without_tenant do
        user_context = UserContext.new(admin_user, organization)
        scope = UserPolicy::Scope.new(user_context, User).resolve
        
        expect(scope).to include(@user1, @user2)
        expect(scope).not_to include(@other_user)
      end
    end
  end

  describe '#index?' do
    it 'grants access to admins' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.index?).to be_truthy
    end

    it 'grants access to staff' do
      user_context = UserContext.new(staff_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.index?).to be_truthy
    end

    it 'denies access to professionals' do
      user_context = UserContext.new(professional_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.index?).to be_falsy
    end

    it 'denies access to parents' do
      user_context = UserContext.new(parent_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.index?).to be_falsy
    end
  end

  describe '#show?' do
    let(:target_user) do
      ActsAsTenant.with_tenant(organization) do
        create(:user, organization: organization)
      end
    end

    it 'allows admins to view any user in organization' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.show?).to be_truthy
    end

    it 'allows staff to view any user in organization' do
      user_context = UserContext.new(staff_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.show?).to be_truthy
    end

    it 'allows users to view themselves' do
      user_context = UserContext.new(professional_user, organization)
      policy = UserPolicy.new(user_context, professional_user)
      expect(policy.show?).to be_truthy
    end

    it 'denies professionals from viewing other users' do
      user_context = UserContext.new(professional_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.show?).to be_falsy
    end

    it 'denies parents from viewing other users' do
      user_context = UserContext.new(parent_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.show?).to be_falsy
    end

    it 'denies access to users from different organizations' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, other_user)
      expect(policy.show?).to be_falsy
    end
  end

  describe '#create?' do
    it 'allows admins to create users' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.create?).to be_truthy
    end

    it 'allows staff to create parent users only' do
      user_context = UserContext.new(staff_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.create?).to be_truthy
    end

    it 'denies professionals from creating users' do
      user_context = UserContext.new(professional_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.create?).to be_falsy
    end

    it 'denies parents from creating users' do
      user_context = UserContext.new(parent_user, organization)
      policy = UserPolicy.new(user_context, User)
      expect(policy.create?).to be_falsy
    end
  end

  describe '#update?' do
    let(:target_user) do
      ActsAsTenant.with_tenant(organization) do
        create(:user, organization: organization)
      end
    end

    it 'allows admins to update any user' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.update?).to be_truthy
    end

    it 'allows staff to update parent users only' do
      parent = ActsAsTenant.with_tenant(organization) do
        create(:user, :guardian, organization: organization)
      end
      professional = ActsAsTenant.with_tenant(organization) do
        create(:user, :professional, organization: organization)
      end
      
      user_context = UserContext.new(staff_user, organization)
      
      policy = UserPolicy.new(user_context, parent)
      expect(policy.update?).to be_truthy
      
      policy = UserPolicy.new(user_context, professional)
      expect(policy.update?).to be_falsy
    end

    it 'allows users to update themselves' do
      user_context = UserContext.new(professional_user, organization)
      policy = UserPolicy.new(user_context, professional_user)
      expect(policy.update?).to be_truthy
    end

    it 'denies updating users from different organizations' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, other_user)
      expect(policy.update?).to be_falsy
    end
  end

  describe '#destroy?' do
    let(:target_user) do
      ActsAsTenant.with_tenant(organization) do
        create(:user, organization: organization)
      end
    end

    it 'allows admins to destroy users (except themselves)' do
      user_context = UserContext.new(admin_user, organization)
      
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.destroy?).to be_truthy
      
      policy = UserPolicy.new(user_context, admin_user)
      expect(policy.destroy?).to be_falsy
    end

    it 'denies staff from destroying users' do
      user_context = UserContext.new(staff_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.destroy?).to be_falsy
    end

    it 'denies professionals from destroying users' do
      user_context = UserContext.new(professional_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.destroy?).to be_falsy
    end

    it 'denies parents from destroying users' do
      user_context = UserContext.new(parent_user, organization)
      policy = UserPolicy.new(user_context, target_user)
      expect(policy.destroy?).to be_falsy
    end
  end

  describe 'multi-tenant security' do
    it 'prevents cross-tenant access even for admins' do
      user_context = UserContext.new(admin_user, organization)
      policy = UserPolicy.new(user_context, other_user)
      
      expect(policy.show?).to be_falsy
      expect(policy.update?).to be_falsy
      expect(policy.destroy?).to be_falsy
    end
  end
end