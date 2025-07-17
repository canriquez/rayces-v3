# Example: RSpec Tests for JWT Authentication
# This example shows comprehensive tests for authentication endpoints

# spec/requests/api/v1/sessions_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  let(:organization) { create(:organization, subdomain: 'test-org') }
  let(:user) { create(:user, organization: organization, password: 'password123') }
  
  before do
    host! "test-org.rayces.com"
  end

  describe 'POST /api/v1/login' do
    context 'with valid credentials' do
      let(:valid_params) do
        {
          user: {
            email: user.email,
            password: 'password123'
          }
        }
      end

      it 'returns JWT token and user data' do
        post '/api/v1/login', params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Logged in successfully.')
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq(user.email)
        
        # Verify JWT token structure
        token = json['token']
        decoded = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key!, true)
        payload = decoded.first
        
        expect(payload['sub']).to eq(user.id)
        expect(payload['email']).to eq(user.email)
        expect(payload['organization_id']).to eq(organization.id)
        expect(payload['role']).to eq(user.role)
      end

      it 'sets Authorization header' do
        post '/api/v1/login', params: valid_params, as: :json
        
        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end
    end

    context 'with invalid credentials' do
      let(:invalid_params) do
        {
          user: {
            email: user.email,
            password: 'wrongpassword'
          }
        }
      end

      it 'returns unauthorized error' do
        post '/api/v1/login', params: invalid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context 'with non-existent user' do
      let(:params) do
        {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
      end

      it 'returns unauthorized error' do
        post '/api/v1/login', params: params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with locked account' do
      before do
        user.update!(locked_at: Time.current)
      end

      let(:params) do
        {
          user: {
            email: user.email,
            password: 'password123'
          }
        }
      end

      it 'returns account locked error' do
        post '/api/v1/login', params: params, as: :json

        expect(response).to have_http_status(:unauthorized)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('locked')
      end
    end
  end

  describe 'DELETE /api/v1/logout' do
    context 'with valid JWT token' do
      let(:headers) do
        { 'Authorization' => "Bearer #{generate_jwt_token(user)}" }
      end

      it 'logs out successfully' do
        delete '/api/v1/logout', headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Logged out successfully.')
        
        # Verify JTI has been updated (token revoked)
        expect(user.reload.jti).not_to eq(user.jti_was)
      end
    end

    context 'without JWT token' do
      it 'returns unauthorized error' do
        delete '/api/v1/logout', as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

# spec/requests/api/v1/registrations_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Registrations', type: :request do
  let(:organization) { create(:organization, subdomain: 'test-org', active: true) }
  
  before do
    host! "test-org.rayces.com"
  end

  describe 'POST /api/v1/signup' do
    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'John',
            last_name: 'Doe',
            phone: '+1234567890'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post '/api/v1/signup', params: valid_params, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Signed up successfully.')
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('newuser@example.com')
        
        # Verify user was created with correct organization
        user = User.last
        expect(user.organization).to eq(organization)
        expect(user.first_name).to eq('John')
        expect(user.last_name).to eq('Doe')
      end

      context 'when email confirmation is required' do
        before do
          allow_any_instance_of(User).to receive(:active_for_authentication?).and_return(false)
        end

        it 'sends confirmation email' do
          post '/api/v1/signup', params: valid_params, as: :json

          expect(response).to have_http_status(:created)
          
          json = JSON.parse(response.body)
          expect(json['message']).to include('confirmation email')
          expect(json['token']).not_to be_present
        end
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          user: {
            email: 'invalid-email',
            password: 'short',
            password_confirmation: 'different',
            first_name: '',
            last_name: ''
          }
        }
      end

      it 'returns validation errors' do
        post '/api/v1/signup', params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to include(match(/email/i))
        expect(json['errors']).to include(match(/password/i))
        expect(json['errors']).to include(match(/first_name/i))
      end
    end

    context 'with inactive organization' do
      before do
        organization.update!(active: false)
      end

      let(:params) do
        {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'returns organization error' do
        post '/api/v1/signup', params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('organization')
      end
    end
  end
end

# Helper method for generating JWT tokens in tests
def generate_jwt_token(user)
  payload = user.jwt_payload
  JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key!, 'HS256')
end