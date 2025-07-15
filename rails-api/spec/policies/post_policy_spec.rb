require 'rails_helper'

RSpec.describe PostPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:other_org_user) { create(:user) }
  
  let(:post) do
    create_with_tenant(user.organization, :post, user: user)
  end
  
  let(:other_org_post) do
    create_with_tenant(other_org_user.organization, :post, user: other_org_user)
  end
  
  subject { described_class }
  
  describe 'permissions' do
    context 'for same organization user' do
      let(:user_context) { UserContext.new(user, organization) }
      let(:policy) { described_class.new(user_context, post) }
      
      it 'allows viewing posts' do
        expect(policy.show?).to be_truthy
      end
      
      it 'allows creating posts' do
        expect(policy.create?).to be_truthy
      end
      
      it 'allows updating own posts' do
        expect(policy.update?).to be_truthy
      end
      
      it 'allows destroying own posts' do
        expect(policy.destroy?).to be_truthy
      end
    end
    
    context 'for different organization user' do
      let(:user_context) { UserContext.new(user, organization) }
      let(:policy) { described_class.new(user_context, other_org_post) }
      
      it 'denies viewing posts from other organizations' do
        expect(policy.show?).to be_falsy
      end
    end
    
    context 'for admin user' do
      let(:user_context) { UserContext.new(admin_user, organization) }
      let(:policy) { described_class.new(user_context, post) }
      
      it 'allows admin to update any post in organization' do
        expect(policy.update?).to be_truthy
      end
      
      it 'allows admin to destroy any post in organization' do
        expect(policy.destroy?).to be_truthy
      end
    end
  end
  
  describe 'Scope' do
    let(:user_context) { UserContext.new(user, organization) }
    let(:scope) { described_class::Scope.new(user_context, Post).resolve }
    
    before do
      # Create posts with proper tenant context
      create_with_tenant(user.organization, :post, user: user)
      create_with_tenant(other_org_user.organization, :post, user: other_org_user)
    end
    
    it 'returns only posts from same organization' do
      # Run scope query within the proper tenant context
      with_tenant(organization) do
        expect(scope.count).to eq(1)
        expect(scope.first.user.organization_id).to eq(organization.id)
      end
    end
  end
end