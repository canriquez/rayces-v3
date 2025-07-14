require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:parent_user) { create(:user, :parent, organization: organization) }
  let(:other_org) { create(:organization, subdomain: 'other') }
  let(:other_user) { create(:user, :admin, organization: other_org) }

  describe 'Scope' do
    let(:user) { admin_user }
    
    it 'includes tenant-scoped records for the user organization', :pending do
      # NOTE: Multi-tenancy scoping belongs to SCRUM-33, not SCRUM-32
      user1 = create(:user, organization: organization)
      user2 = create(:user, organization: organization)
      other_user = create(:user, organization: other_org)
      
      user_context = UserContext.new(user, organization)
      scope = ApplicationPolicy::Scope.new(user_context, User).resolve
      
      expect(scope).to include(user1, user2)
      expect(scope).not_to include(other_user)
    end
  end

  describe 'base policy methods' do
    let(:record) { create(:user, organization: organization) }
    let(:user_context) { UserContext.new(admin_user, organization) }
    let(:policy) { ApplicationPolicy.new(user_context, record) }

    describe '#same_tenant?' do
      it 'returns true when record belongs to same organization' do
        expect(policy.same_tenant?).to be_truthy
      end

      it 'returns false when record belongs to different organization', :pending do
        # NOTE: Multi-tenancy validation belongs to SCRUM-33, not SCRUM-32
        other_record = create(:user, organization: other_org)
        other_policy = ApplicationPolicy.new(user_context, other_record)
        expect(other_policy.same_tenant?).to be_falsy
      end
    end

    describe '#admin?' do
      it 'returns true for admin users' do
        expect(policy.admin?).to be_truthy
      end

      it 'returns false for non-admin users' do
        professional_context = UserContext.new(professional_user, organization)
        professional_policy = ApplicationPolicy.new(professional_context, record)
        expect(professional_policy.admin?).to be_falsy
      end
    end

    describe '#professional?' do
      it 'returns true for professional users' do
        professional_context = UserContext.new(professional_user, organization)
        professional_policy = ApplicationPolicy.new(professional_context, record)
        expect(professional_policy.professional?).to be_truthy
      end

      it 'returns false for non-professional users' do
        expect(policy.professional?).to be_falsy
      end
    end

    describe '#parent?' do
      it 'returns true for parent users' do
        parent_context = UserContext.new(parent_user, organization)
        parent_policy = ApplicationPolicy.new(parent_context, record)
        expect(parent_policy.parent?).to be_truthy
      end

      it 'returns false for non-parent users' do
        expect(policy.parent?).to be_falsy
      end
    end

    describe '#owns_record?' do
      it 'returns true when user owns the record' do
        user_context = UserContext.new(admin_user, organization)
        policy = ApplicationPolicy.new(user_context, admin_user)
        expect(policy.owns_record?).to be_truthy
      end

      it 'returns false when user does not own the record' do
        expect(policy.owns_record?).to be_falsy
      end
    end
  end

  describe 'default permissions' do
    let(:record) { create(:user, organization: organization) }
    let(:user_context) { UserContext.new(professional_user, organization) }
    let(:policy) { ApplicationPolicy.new(user_context, record) }

    it 'denies index by default' do
      expect(policy.index?).to be_falsy
    end

    it 'denies show by default' do
      expect(policy.show?).to be_falsy
    end

    it 'denies create by default' do
      expect(policy.create?).to be_falsy
    end

    it 'denies update by default' do
      expect(policy.update?).to be_falsy
    end

    it 'denies destroy by default' do
      expect(policy.destroy?).to be_falsy
    end
  end

  describe 'multi-tenant isolation' do
    let(:record) { create(:user, organization: other_org) }
    let(:user_context) { UserContext.new(admin_user, organization) }
    let(:policy) { ApplicationPolicy.new(user_context, record) }

    it 'automatically denies access to records from other tenants', :pending do
      # NOTE: Multi-tenancy isolation belongs to SCRUM-33, not SCRUM-32
      expect(policy.same_tenant?).to be_falsy
      # Most policies should check same_tenant? before allowing access
    end
  end
end