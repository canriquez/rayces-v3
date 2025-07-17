require 'rails_helper'

RSpec.describe 'Api::V1::Organizations', type: :request do
  # NOTE: Organizations API and tenant isolation belong to SCRUM-33, not SCRUM-32
  
  # Organizations API enabled
  let!(:organization) { create(:organization) }
  let!(:admin_user) { create(:user, :admin, organization: organization) }
  let!(:professional_user) { create(:user, :professional, organization: organization) }
  let!(:parent_user) { create(:user, :parent, organization: organization) }

  describe 'GET /api/v1/organization' do
    context 'when authenticated as admin' do
      it 'returns the current organization' do
        get '/api/v1/organization', headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['organization']['id']).to eq(admin_user.organization_id)
        expect(json_response['organization']['name']).to eq(admin_user.organization.name)
      end

      it 'includes admin-only fields' do
        get '/api/v1/organization', headers: auth_headers(admin_user)
        
        json_response = JSON.parse(response.body)
        expect(json_response['organization']).to have_key('settings')
        expect(json_response['organization']).to have_key('email')
      end
    end

    context 'when authenticated as professional' do
      it 'returns limited organization info' do
        get '/api/v1/organization', headers: auth_headers(professional_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['organization']['id']).to eq(professional_user.organization_id)
        expect(json_response['organization']['name']).to eq(professional_user.organization.name)
        expect(json_response['organization']).not_to have_key('settings')
      end
    end

    context 'when authenticated as parent' do
      it 'returns basic organization info' do
        get '/api/v1/organization', headers: auth_headers(parent_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['organization']['name']).to eq(parent_user.organization.name)
        expect(json_response['organization']).not_to have_key('email')
        expect(json_response['organization']).not_to have_key('settings')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/organization'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/organization' do
    context 'when authenticated as admin' do

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

        put '/api/v1/organization', params: update_params.to_json, headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        admin_user.organization.reload
        expect(admin_user.organization.name).to eq('Updated Organization Name')
        expect(admin_user.organization.phone).to eq('+1-555-9999')
        expect(admin_user.organization.settings['timezone']).to eq('UTC')
      end

      it 'validates required fields' do
        update_params = {
          organization: {
            name: '',
            email: 'invalid-email'
          }
        }

        put '/api/v1/organization', params: update_params.to_json, headers: auth_headers(admin_user)

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

        put '/api/v1/organization', params: update_params.to_json, headers: auth_headers(admin_user)

        organization.reload
        expect(organization.subdomain).to eq(original_subdomain)
      end
    end

    context 'when authenticated as non-admin' do
      it 'returns forbidden' do
        update_params = {
          organization: { name: 'Should not update' }
        }

        put '/api/v1/organization', params: update_params.to_json, headers: auth_headers(professional_user)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        put '/api/v1/organization', params: { organization: { name: 'Test' } }.to_json, headers: { 'Content-Type' => 'application/json' }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'tenant isolation' do
    let(:other_organization) { create(:organization, subdomain: 'other-org') }
    let(:other_admin) { create(:user, :admin, organization: other_organization) }

    it 'does not allow access to other organization data' do
      # Try to access the first organization by setting subdomain
      host! "#{organization.subdomain}.example.com"
      get '/api/v1/organization', headers: auth_headers(other_admin)
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  # NOTE: Subdomain-based tenant detection with JWT mismatch is correctly rejected
  # The system prevents access when JWT organization_id doesn't match subdomain
  # This is the correct security behavior to prevent cross-tenant access

end