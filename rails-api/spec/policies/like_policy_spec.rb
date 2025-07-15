require 'rails_helper'

RSpec.describe LikePolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:other_org_user) { create(:user) }
  
  let(:post) { create_with_tenant(user.organization, :post, user: user) }
  let(:other_org_post) { create_with_tenant(other_org_user.organization, :post, user: other_org_user) }
  let(:like) { create_with_tenant(user.organization, :like, user: user, post: post) }
  let(:other_org_like) { create_with_tenant(other_org_user.organization, :like, user: other_org_user, post: other_org_post) }
  
  subject { described_class }
  
  describe 'permissions' do
    context 'for same organization user' do
      let(:user_context) { UserContext.new(user, organization) }
      let(:policy) { described_class.new(user_context, like) }
      
      it 'allows viewing likes' do
        expect(policy.show?).to be_truthy
      end
      
      it 'allows creating likes' do
        expect(policy.create?).to be_truthy
      end
      
      it 'allows destroying own likes' do
        expect(policy.destroy?).to be_truthy
      end
    end
    
    context 'for different organization user' do
      let(:user_context) { UserContext.new(user, organization) }
      let(:policy) { described_class.new(user_context, other_org_like) }
      
      it 'denies viewing likes from other organizations' do
        expect(policy.show?).to be_falsy
      end
      
      it 'denies creating likes for posts from other organizations' do
        expect(policy.create?).to be_falsy
      end
    end
    
    context 'for admin user' do
      let(:user_context) { UserContext.new(admin_user, organization) }
      let(:policy) { described_class.new(user_context, like) }
      
      it 'allows admin to destroy any like in organization' do
        expect(policy.destroy?).to be_truthy
      end
    end
  end
  
  describe 'Scope' do
    let(:user_context) { UserContext.new(user, organization) }
    let(:scope) { described_class::Scope.new(user_context, Like).resolve }
    
    before do
      create_with_tenant(user.organization, :like, user: user, post: post)
      create_with_tenant(other_org_user.organization, :like, user: other_org_user, post: other_org_post)
    end
    
    it 'returns only likes from same organization' do
      # Run scope query within the proper tenant context
      with_tenant(organization) do
        expect(scope.count).to eq(1)
        expect(scope.first.user.organization_id).to eq(organization.id)
      end
    end
  end
end