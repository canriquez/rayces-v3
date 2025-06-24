# spec/controllers/users_controller_spec.rb
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_token) { 'valid_google_token' }
  let(:invalid_token) { 'invalid_google_token' }
  let(:user_info) do
    {
      'name' => 'Carlos Anriquez',
      'email' => 'carlos.anriquez@spatialnetworks.com',
      'image' => 'https://lh3.googleusercontent.com/a/ACg8ocJgN3X7fk9zUvdZSeg2S-dVQV5TAJY7fjUsHey3gvGC77CqU7Y=s96-c',
      'username' => 'carlosanriquez',
      'uid' => '116790173757814684761'
    }
  end

  before do
    allow_any_instance_of(GoogleIDToken::Validator).to receive(:check)
      .with(valid_token, ENV['GOOGLE_CLIENT_ID'])
      .and_return(user_info)
    allow_any_instance_of(GoogleIDToken::Validator).to receive(:check)
      .with(invalid_token, ENV['GOOGLE_CLIENT_ID'])
      .and_raise(GoogleIDToken::ValidationError)
  end

  describe 'POST #sign_in' do
    context 'with valid token' do
      it 'creates a new user if user does not exist' do
        expect {
          request.headers['Authorization'] = "Bearer #{valid_token}"
          post :sign_in
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['new_user']).to be_truthy
      end

      it 'does not create a new user if user already exists' do
        User.create!(user_info)

        expect {
          request.headers['Authorization'] = "Bearer #{valid_token}"
          post :sign_in
        }.not_to change(User, :count)
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['new_user']).to be_falsey
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        request.headers['Authorization'] = "Bearer #{invalid_token}"
        post :sign_in

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end
  end
end
