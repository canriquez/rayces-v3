# Pundit Policy Test Example
# This demonstrates best practices for testing Pundit policies with RSpec

require 'rails_helper'

RSpec.describe PostPolicy do
  subject { described_class }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:other_org_user) { create(:user) }
  let(:user_context) { UserContext.new(user, organization) }
  let(:admin_context) { UserContext.new(admin_user, organization) }

  describe "permissions" do
    permissions :show?, :update?, :destroy? do
      it "allows access to posts in same organization" do
        post = create(:post, user: user, organization: organization)
        expect(subject).to permit(user_context, post)
      end

      it "denies access to posts in other organizations" do
        post = create(:post, user: other_org_user)
        expect(subject).not_to permit(user_context, post)
      end

      it "allows admin access to all posts in organization" do
        post = create(:post, user: user, organization: organization)
        expect(subject).to permit(admin_context, post)
      end
    end

    permissions :create? do
      it "allows authenticated users to create posts" do
        post = build(:post, user: user, organization: organization)
        expect(subject).to permit(user_context, post)
      end
    end
  end

  describe "scope" do
    let(:policy_scope) { Pundit.policy_scope(user_context, Post) }

    it "returns posts from user's organization only" do
      user_post = create(:post, user: user, organization: organization)
      other_post = create(:post, user: other_org_user)
      
      expect(policy_scope).to include(user_post)
      expect(policy_scope).not_to include(other_post)
    end
  end
end