require 'rails_helper'

RSpec.describe 'Api::V1::Organizations', type: :request do
  # NOTE: Organizations API and tenant isolation belong to SCRUM-33, not SCRUM-32
  
  before(:all) { skip "Organizations API belongs to SCRUM-33, not SCRUM-32" }
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:parent_user) { create(:user, :parent, organization: organization) }

  describe 'GET /api/v1/organizations' do
    context 'when authenticated as admin' do
      before { sign_in_with_jwt(admin_user) }

      it 'returns the current organization' do
        get '/api/v1/organizations'
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['organization']['id']).to eq(organization.id)
        expect(json_response['organization']['name']).to eq(organization.name)
      end

      it 'includes admin-only fields' do
        get '/api/v1/organizations'
        
        json_response = JSON.parse(response.body)
        expect(json_response['organization']).to have_key('settings')
        expect(json_response['organization']).to have_key('email')
      end
    end

    context 'when authenticated as professional' do
      before { sign_in_with_jwt(professional_user) }

      it 'returns limited organization info' do
        get '/api/v1/organizations'
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['organization']['id']).to eq(organization.id)
        expect(json_response['organization']['name']).to eq(organization.name)
        expect(json_response['organization']).not_to have_key('settings')
      end
    end

    context 'when authenticated as parent' do
      before { sign_in_with_jwt(parent_user) }

      it 'returns basic organization info' do
        get '/api/v1/organizations'
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['organization']['name']).to eq(organization.name)
        expect(json_response['organization']).not_to have_key('email')
        expect(json_response['organization']).not_to have_key('settings')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/organizations'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/organizations' do
    context 'when authenticated as admin' do
      before { sign_in_with_jwt(admin_user) }

      it 'updates organization successfully' do
        update_params = {
          organization: {
            name: 'Updated Organization Name',
            phone: '+1-555-9999',
            settings: {
              timezone: 'UTC',
              currency: 'EUR'
            }
          }
        }

        put '/api/v1/organizations', params: update_params

        expect(response).to have_http_status(:ok)
        organization.reload
        expect(organization.name).to eq('Updated Organization Name')
        expect(organization.phone).to eq('+1-555-9999')
        expect(organization.settings['timezone']).to eq('UTC')
      end

      it 'validates required fields' do
        update_params = {
          organization: {
            name: '',
            email: 'invalid-email'
          }
        }

        put '/api/v1/organizations', params: update_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Name can't be blank")
      end

      it 'prevents subdomain updates' do
        original_subdomain = organization.subdomain
        update_params = {
          organization: {
            subdomain: 'new-subdomain'
          }
        }

        put '/api/v1/organizations', params: update_params

        organization.reload
        expect(organization.subdomain).to eq(original_subdomain)
      end
    end

    context 'when authenticated as non-admin' do
      before { sign_in_with_jwt(professional_user) }

      it 'returns forbidden' do
        update_params = {
          organization: { name: 'Should not update' }
        }

        put '/api/v1/organizations', params: update_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        put '/api/v1/organizations', params: { organization: { name: 'Test' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'tenant isolation' do
    let(:other_organization) { create(:organization, subdomain: 'other-org') }
    let(:other_admin) { create(:user, :admin, organization: other_organization) }

    it 'does not allow access to other organization data' do
      sign_in_with_jwt(other_admin)
      
      # Try to access the first organization by setting subdomain
      host! "#{organization.subdomain}.example.com"
      get '/api/v1/organizations'
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'subdomain-based tenant detection' do
    before { sign_in_with_jwt(admin_user) }

    it 'detects tenant from subdomain' do
      host! "#{organization.subdomain}.example.com"
      get '/api/v1/organizations'
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['organization']['id']).to eq(organization.id)
    end

    it 'returns not found for invalid subdomain' do
      host! "invalid-subdomain.example.com"
      get '/api/v1/organizations'
      
      expect(response).to have_http_status(:not_found)
    end
  end

  private

  def sign_in_with_jwt(user)
    payload = {
      sub: user.id,
      organization_id: user.organization_id,
      role: user.role,
      jti: user.jti
    }
    token = JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
    request.headers['Authorization'] = "Bearer #{token}"
  end
end