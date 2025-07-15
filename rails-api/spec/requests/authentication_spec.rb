require 'rails_helper'

RSpec.describe 'Authentication & Authorization', type: :request do
  # NOTE: JWT authentication belongs to SCRUM-32, but multi-tenancy features belong to SCRUM-33
  # Tests updated for SCRUM-33 multi-tenancy implementation
  let(:organization) { create(:organization, subdomain: 'test-auth') }
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:professional_user) { create(:user, :professional, organization: organization) }
  let(:parent_user) { create(:user, :parent, organization: organization) }
  let(:other_org) { create(:organization, subdomain: 'other-auth') }
  let(:other_user) { create(:user, :admin, organization: other_org) }

  before do
    # Create default roles for both organizations
    Role.create_defaults_for_organization(organization)
    Role.create_defaults_for_organization(other_org)
    
    # Set up roles for each organization
    ActsAsTenant.with_tenant(organization) do
      admin_user.assign_role('admin')
      professional_user.assign_role('professional')
      parent_user.assign_role('client')
    end

    ActsAsTenant.with_tenant(other_org) do
      other_user.assign_role('admin')
    end
  end

  describe 'JWT Authentication' do
    context 'with valid JWT token' do
      it 'allows access to protected endpoints' do
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:ok)
      end

      it 'sets current user from JWT payload' do
        host! host_for_organization(organization)
        get '/api/v1/users', headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:ok)
        # The controller should have access to current_user
      end

      it 'sets organization context from JWT payload' do
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(organization.id)
      end
    end

    context 'with invalid JWT token' do
      it 'rejects requests with malformed tokens' do
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: { 'Authorization' => 'Bearer invalid-token' }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Invalid token')
      end

      it 'rejects requests with expired tokens' do
        expired_token = create_expired_jwt_token(admin_user)
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: { 'Authorization' => "Bearer #{expired_token}" }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Token expired')
      end

      it 'rejects requests with tokens signed with wrong key' do
        invalid_token = create_invalid_jwt_token
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: { 'Authorization' => "Bearer #{invalid_token}" }
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects requests with revoked tokens (different JTI)' do
        # Change user's JTI to simulate token revocation
        original_jti = admin_user.jti
        admin_user.update!(jti: SecureRandom.uuid)
        
        # Use token with old JTI
        payload = {
          sub: admin_user.id,
          organization_id: admin_user.organization_id,
          role: admin_user.role,
          jti: original_jti # Old JTI
        }
        old_token = JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
        
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: { 'Authorization' => "Bearer #{old_token}" }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Invalid token')
      end
    end

    context 'without authentication token' do
      it 'rejects requests without authorization header' do
        host! host_for_organization(organization)
        get '/api/v1/organization'
        
        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects requests with empty authorization header' do
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: { 'Authorization' => '' }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Google OAuth Fallback' do
    context 'when JWT is not present but Google session exists' do
      before do
        # Simulate Google OAuth session
        allow_any_instance_of(ApplicationController).to receive(:google_user_present?).and_return(true)
        allow_any_instance_of(ApplicationController).to receive(:authenticate_google_user).and_return(admin_user)
      end

      it 'authenticates user via Google OAuth' do
        host! host_for_organization(organization)
        get '/api/v1/organization'
        
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when neither JWT nor Google session exists' do
      it 'returns unauthorized' do
        host! host_for_organization(organization)
        get '/api/v1/organization'
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Multi-tenant Security' do
    context 'when user belongs to different organization' do
      it 'rejects access even with valid JWT' do
        # User belongs to other_org, but trying to access organization
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: auth_headers(other_user)
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('organization access')
      end
    end

    context 'when subdomain does not match organization' do
      it 'rejects access with mismatched subdomain' do
        # Valid user but wrong subdomain
        host! 'invalid-subdomain.example.com'
        get '/api/v1/organization', headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when JWT organization_id does not match subdomain organization' do
      it 'rejects access with organization mismatch' do
        # Manually create JWT with wrong organization_id
        payload = {
          sub: admin_user.id,
          organization_id: other_org.id, # Wrong organization
          role: admin_user.role,
          jti: admin_user.jti
        }
        mismatched_token = JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
        
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: { 'Authorization' => "Bearer #{mismatched_token}" }
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'Role-based Authorization' do
    describe 'admin endpoints' do
      it 'allows admin access to organization updates' do
        host! host_for_organization(organization)
        put '/api/v1/organization', 
            params: { organization: { name: 'Updated Name' } },
            headers: auth_headers(admin_user)
        
        expect(response).to have_http_status(:ok)
      end

      it 'denies non-admin access to organization updates' do
        host! host_for_organization(organization)
        put '/api/v1/organization', 
            params: { organization: { name: 'Updated Name' } },
            headers: auth_headers(parent_user)
        
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'user access control' do
      it 'allows authenticated users to view users list' do
        host! host_for_organization(organization)
        get '/api/v1/users', headers: auth_headers(professional_user)
        
        expect(response).to have_http_status(:ok)
      end

      it 'allows users to view their own profile' do
        host! host_for_organization(organization)
        get "/api/v1/users/#{professional_user.id}", headers: auth_headers(professional_user)
        
        expect(response).to have_http_status(:ok)
      end

      it 'restricts access without proper authentication' do
        host! host_for_organization(organization)
        get '/api/v1/users'
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Token Refresh and Revocation' do
    context 'when user changes JTI (simulates logout)' do
      it 'invalidates old tokens' do
        # Make request with current token
        host! host_for_organization(organization)
        get '/api/v1/organization', headers: auth_headers(admin_user)
        expect(response).to have_http_status(:ok)
        
        # Change JTI (simulate logout/token revocation)
        old_headers = auth_headers(admin_user)
        admin_user.update!(jti: SecureRandom.uuid)
        
        # Try to use old token
        get '/api/v1/organization', headers: old_headers
        expect(response).to have_http_status(:unauthorized)
        
        # New token should work
        get '/api/v1/organization', headers: auth_headers(admin_user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Error Response Format' do
    it 'returns consistent error format for unauthorized requests' do
      host! host_for_organization(organization)
      get '/api/v1/organization'
      
      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('error')
      expect(json_response).to have_key('status')
      expect(json_response['status']).to eq(401)
    end

    it 'returns consistent error format for forbidden requests' do
      host! host_for_organization(organization)
      put '/api/v1/organization', 
          params: { organization: { name: 'Test' } },
          headers: auth_headers(parent_user)
      
      expect(response).to have_http_status(:forbidden)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('error')
      expect(json_response).to have_key('status')
      expect(json_response['status']).to eq(403)
    end
  end

  describe 'Rate Limiting and Security Headers' do
    it 'includes security headers in responses' do
      host! host_for_organization(organization)
      get '/api/v1/organization', headers: auth_headers(admin_user)
      
      expect(response.headers).to have_key('X-Content-Type-Options')
      expect(response.headers).to have_key('X-Frame-Options')
    end
  end

  describe 'Performance' do
    it 'authenticates requests quickly' do
      host! host_for_organization(organization)
      
      start_time = Time.current
      get '/api/v1/organization', headers: auth_headers(admin_user)
      auth_time = Time.current - start_time
      
      expect(response).to have_http_status(:ok)
      expect(auth_time).to be < 0.1.seconds
    end
  end

  private

  def host_for_organization(organization)
    "#{organization.subdomain}.example.com"
  end

  def auth_headers(user)
    token = jwt_token_for(user)
    { 'Authorization' => "Bearer #{token}" }
  end

  def jwt_token_for(user)
    payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      organization_id: user.organization_id,
      jti: user.jti,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(
      payload, 
      Rails.application.credentials.devise_jwt_secret_key || Rails.application.credentials.secret_key_base,
      'HS256'
    )
  end

  def create_expired_jwt_token(user)
    payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      organization_id: user.organization_id,
      jti: user.jti,
      exp: 1.hour.ago.to_i # Expired
    }
    
    JWT.encode(
      payload, 
      Rails.application.credentials.devise_jwt_secret_key || Rails.application.credentials.secret_key_base,
      'HS256'
    )
  end

  def create_invalid_jwt_token
    payload = {
      sub: 999,
      email: "invalid@example.com",
      role: "admin",
      organization_id: 999,
      jti: SecureRandom.uuid,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(payload, "wrong-secret-key", 'HS256')
  end

  def json_response
    JSON.parse(response.body)
  end
end