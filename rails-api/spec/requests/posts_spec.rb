require 'rails_helper'

RSpec.describe 'Posts API', type: :request do
  # Clear default tenant to ensure proper isolation
  before(:each) do
    ActsAsTenant.current_tenant = nil
  end
  
  let(:organization) { create(:organization) }
  let(:user) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, organization: organization)
    end
  end
  let(:admin_user) do
    ActsAsTenant.with_tenant(organization) do
      create(:user, :admin, organization: organization)
    end
  end
  let(:other_org) { create(:organization) }
  let(:other_org_user) do
    ActsAsTenant.with_tenant(other_org) do
      create(:user, organization: other_org)
    end
  end
  
  let!(:user_post) do
    ActsAsTenant.with_tenant(organization) do
      create(:post, user: user, organization: organization, content: 'User post content')
    end
  end
  let!(:other_org_post) do
    ActsAsTenant.with_tenant(other_org) do
      create(:post, user: other_org_user, organization: other_org, content: 'Other org post content')
    end
  end
  
  describe 'GET /posts' do
    it 'returns posts from same organization only' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      get '/posts', headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(user_post.id)
    end
    
    it 'requires authentication' do
      get '/posts'
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'GET /posts/:id' do
    it 'allows viewing posts in same organization' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      get "/posts/#{user_post.id}", headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(json_response['id']).to eq(user_post.id)
    end
    
    it 'denies viewing posts from other organizations' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      get "/posts/#{other_org_post.id}", headers: headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe 'POST /posts' do
    let(:valid_params) { { post: { content: 'New Post Content' } } }
    
    it 'allows creating posts' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      send(:post, '/posts', params: valid_params.to_json, headers: headers)
      
      expect(response).to have_http_status(:created)
      expect(json_response['content']).to eq('New Post Content')
    end
    
    it 'requires authentication' do
      send(:post, '/posts', params: valid_params)
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'PUT /posts/:id' do
    let(:update_params) { { post: { content: 'Updated Content' } } }
    
    it 'allows updating own posts' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      put "/posts/#{user_post.id}", params: update_params.to_json, headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(json_response['content']).to eq('Updated Content')
    end
    
    it 'denies updating posts from other organizations' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      put "/posts/#{other_org_post.id}", params: update_params.to_json, headers: headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe 'DELETE /posts/:id' do
    it 'allows deleting own posts' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      delete "/posts/#{user_post.id}", headers: headers
      
      expect(response).to have_http_status(:no_content)
    end
    
    it 'denies deleting posts from other organizations' do
      headers = auth_headers(user).merge({
        'X-Organization-Id' => organization.id.to_s,
        'X-Organization-Subdomain' => organization.subdomain
      })
      
      delete "/posts/#{other_org_post.id}", headers: headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
end
