require 'rails_helper'

RSpec.describe 'Likes API', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:other_org_user) { create(:user) }
  
  let!(:post) { create(:post, user: user) }
  let!(:other_org_post) { create(:post, user: other_org_user) }
  let!(:like) { create(:like, user: user, post: post) }
  let!(:other_org_like) { create(:like, user: other_org_user, post: other_org_post) }
  
  describe 'GET /posts/:post_id/likes' do
    it 'returns likes for posts in same organization' do
      get "/posts/#{post.id}/likes", headers: auth_headers(user)
      
      expect(response).to have_http_status(:ok)
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(like.id)
    end
    
    it 'requires authentication' do
      get "/posts/#{post.id}/likes"
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'POST /posts/:post_id/likes' do
    let(:valid_params) { { like: { post_id: post.id } } }
    
    it 'allows creating likes for posts in same organization' do
      post "/posts/#{post.id}/likes", params: valid_params, headers: auth_headers(user)
      
      expect(response).to have_http_status(:created)
      expect(json_response['user']['id']).to eq(user.id)
    end
    
    it 'denies creating likes for posts from other organizations' do
      post "/posts/#{other_org_post.id}/likes", params: valid_params, headers: auth_headers(user)
      
      expect(response).to have_http_status(:forbidden)
    end
    
    it 'requires authentication' do
      post "/posts/#{post.id}/likes", params: valid_params
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'DELETE /posts/:post_id/likes' do
    it 'allows deleting own likes' do
      delete "/posts/#{post.id}/likes", headers: auth_headers(user)
      
      expect(response).to have_http_status(:no_content)
    end
    
    it 'denies deleting likes from other organizations' do
      delete "/posts/#{other_org_post.id}/likes", headers: auth_headers(user)
      
      expect(response).to have_http_status(:not_found)
    end
    
    it 'requires authentication' do
      delete "/posts/#{post.id}/likes"
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
end