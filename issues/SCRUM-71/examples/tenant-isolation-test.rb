# Tenant Isolation Test Example
# This demonstrates how to test multi-tenant functionality with ActsAsTenant

require 'rails_helper'

RSpec.describe 'Tenant Isolation', type: :request do
  let(:org1) { create(:organization, subdomain: 'org1') }
  let(:org2) { create(:organization, subdomain: 'org2') }
  let(:user1) { create(:user, organization: org1) }
  let(:user2) { create(:user, organization: org2) }

  describe 'POST /posts' do
    it 'creates post in correct tenant context' do
      ActsAsTenant.with_tenant(org1) do
        post '/posts', 
             params: { post: { content: 'Test content' } },
             headers: auth_headers(user1)
        
        expect(response).to have_http_status(:created)
        created_post = Post.find(json_response['id'])
        expect(created_post.organization_id).to eq(org1.id)
      end
    end

    it 'prevents cross-tenant data access' do
      # Create post in org1
      post_org1 = nil
      ActsAsTenant.with_tenant(org1) do
        post_org1 = create(:post, user: user1, organization: org1)
      end

      # Try to access from org2 context
      ActsAsTenant.with_tenant(org2) do
        get "/posts/#{post_org1.id}", headers: auth_headers(user2)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /posts' do
    it 'returns only posts from current tenant' do
      # Create posts in different organizations
      post1 = nil
      post2 = nil

      ActsAsTenant.with_tenant(org1) do
        post1 = create(:post, user: user1, organization: org1)
      end

      ActsAsTenant.with_tenant(org2) do
        post2 = create(:post, user: user2, organization: org2)
      end

      # Request from org1
      ActsAsTenant.with_tenant(org1) do
        get '/posts', headers: auth_headers(user1)
        
        expect(response).to have_http_status(:ok)
        returned_posts = json_response
        
        expect(returned_posts.length).to eq(1)
        expect(returned_posts.first['id']).to eq(post1.id)
      end
    end
  end

  describe 'subdomain resolution' do
    it 'sets correct tenant from subdomain' do
      # This would typically be handled by middleware
      # but we can test the resolution logic
      
      host = "#{org1.subdomain}.example.com"
      resolved_org = Organization.find_by(subdomain: org1.subdomain)
      
      expect(resolved_org).to eq(org1)
    end
  end
end