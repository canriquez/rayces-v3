require 'rails_helper'

RSpec.describe 'Posts API', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:other_org_user) { create(:user) }
  
  let!(:user_post) { create(:post, user: user) }
  let!(:other_org_post) { create(:post, user: other_org_user) }
  
  describe 'GET /posts' do
    it 'returns posts from same organization only' do
      get '/posts', headers: auth_headers(user)
      
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
      get "/posts/#{user_post.id}", headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_response['id']).to eq(user_post.id)
    end
    
    it 'denies viewing posts from other organizations' do
      get "/posts/#{other_org_post.id}", headers: auth_headers(user)
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe 'POST /posts' do
    let(:valid_params) { { post: { content: 'New Post Content' } } }
    
    it 'allows creating posts' do
      send(:post, '/posts', params: valid_params, headers: auth_headers(user))
      
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
      put "/posts/#{user_post.id}", params: update_params, headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_response['content']).to eq('Updated Content')
    end
    
    it 'denies updating posts from other organizations' do
      put "/posts/#{other_org_post.id}", params: update_params, headers: auth_headers(user)
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe 'DELETE /posts/:id' do
    it 'allows deleting own posts' do
      delete "/posts/#{user_post.id}", headers: auth_headers(user)
      
      expect(response).to have_http_status(:no_content)
    end
    
    it 'denies deleting posts from other organizations' do
      delete "/posts/#{other_org_post.id}", headers: auth_headers(user)
      
      expect(response).to have_http_status(:forbidden)
    end
  end
end
