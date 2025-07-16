require 'rails_helper'

RSpec.describe 'Likes API', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  
  # Create users in proper tenant context with roles
  let(:user) do
    u = create(:user, organization: organization)
    ActsAsTenant.with_tenant(organization) do
      Role.create_defaults_for_organization(organization)
      u.assign_role('client')  # Assign basic role
    end
    u.reload  # Reload to get the role association
    u
  end
  
  let(:admin_user) do
    ActsAsTenant.with_tenant(organization) do
      u = create(:user, organization: organization)
      Role.create_defaults_for_organization(organization)
      u.assign_role('admin')
      u
    end
  end
  
  let(:other_org_user) do
    ActsAsTenant.with_tenant(other_organization) do
      u = create(:user, organization: other_organization)
      Role.create_defaults_for_organization(other_organization)
      u.assign_role('client')
      u
    end
  end
  
  # Create posts in proper tenant context
  let!(:test_post) do
    ActsAsTenant.with_tenant(organization) do
      create(:post, user: user, organization: organization)
    end
  end
  
  let!(:other_org_post) do
    ActsAsTenant.with_tenant(other_organization) do
      create(:post, user: other_org_user, organization: other_organization)
    end
  end
  
  # Create likes in proper tenant context
  let!(:like) do
    ActsAsTenant.with_tenant(organization) do
      create(:like, user: user, post: test_post, organization: organization)
    end
  end
  
  let!(:other_org_like) do
    ActsAsTenant.with_tenant(other_organization) do
      create(:like, user: other_org_user, post: other_org_post, organization: other_organization)
    end
  end
  
  describe 'GET /posts/:post_id/like' do
    it 'returns like status for posts in same organization' do
      headers = auth_headers(user).merge('X-Organization-Id' => organization.id.to_s)
      get "/posts/#{test_post.id}/like", headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(json_response['id']).to eq(like.id)
    end
    
    it 'requires authentication' do
      get "/posts/#{test_post.id}/like"
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'POST /posts/:post_id/like' do
    let(:valid_params) { { like: { post_id: test_post.id } } }
    
    it 'allows creating likes for posts in same organization' do
      # Remove existing like first
      like.destroy if like.persisted?
      
      # Use explicit HTTP verb to avoid method name conflict
      headers = auth_headers(user).merge('X-Organization-Id' => organization.id.to_s)
      perform_request('POST', "/posts/#{test_post.id}/like", valid_params, headers)
      
      expect(response).to have_http_status(:created)
      expect(json_response['user']['id']).to eq(user.id)
    end
    
    it 'denies creating likes for posts from other organizations' do
      headers = auth_headers(user).merge('X-Organization-Id' => organization.id.to_s)
      perform_request('POST', "/posts/#{other_org_post.id}/like", valid_params, headers)
      
      expect(response).to have_http_status(:forbidden)
    end
    
    it 'requires authentication' do
      perform_request('POST', "/posts/#{test_post.id}/like", valid_params, {})
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'DELETE /posts/:post_id/like' do
    it 'allows deleting own likes' do
      headers = auth_headers(user).merge('X-Organization-Id' => organization.id.to_s)
      delete "/posts/#{test_post.id}/like", headers: headers
      
      expect(response).to have_http_status(:no_content)
    end
    
    it 'denies deleting likes from other organizations' do
      headers = auth_headers(user).merge('X-Organization-Id' => organization.id.to_s)
      delete "/posts/#{other_org_post.id}/like", headers: headers
      
      expect(response).to have_http_status(:not_found)
    end
    
    it 'requires authentication' do
      delete "/posts/#{test_post.id}/like"
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  private
  
  def json_response
    JSON.parse(response.body)
  end
  
  def perform_request(method_name, path, params, headers)
    case method_name.upcase
    when 'POST'
      send(:post, path, params: params.to_json, headers: headers)
    when 'GET'
      send(:get, path, headers: headers)
    when 'DELETE'
      send(:delete, path, headers: headers)
    end
  end
end