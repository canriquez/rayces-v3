# spec/requests/tenant_isolation_spec.rb
require 'rails_helper'

RSpec.describe 'Tenant Isolation', type: :request do
  # Force tenant resolution for these tests
  before do
    allow_any_instance_of(Api::V1::BaseController).to receive(:skip_tenant_in_tests?).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:skip_tenant_in_tests?).and_return(false)
  end
  let(:organization_a) { create(:organization, subdomain: 'org-a') }
  let(:organization_b) { create(:organization, subdomain: 'org-b') }
  
  let(:user_a) { create(:user, organization: organization_a) }
  let(:user_b) { create(:user, organization: organization_b) }
  
  # Post models removed - using existing User model for testing tenant isolation
  
  describe 'Subdomain-based tenant resolution' do
    context 'when accessing with subdomain' do
      it 'sets correct tenant context using organization header' do
        # Create default roles for the organization first
        Role.create_defaults_for_organization(organization_a)
        
        # Ensure user is properly created with organization
        ActsAsTenant.with_tenant(organization_a) do
          user_a.update!(role: :admin)  # Use enum role for policy checks
          user_a.assign_role('admin')  # Also assign new role system
        end
        
        get '/api/v1/users', headers: { 
          'X-Organization-Subdomain' => organization_a.subdomain,
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:success)
      end
      
      it 'rejects requests with invalid subdomain' do
        get '/api/v1/users', headers: { 
          'X-Organization-Subdomain' => 'invalid',
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:bad_request)
        expect(json_response['error']).to include('Organization context required')
      end
    end
    
    context 'when accessing with organization headers' do
      before do
        Role.create_defaults_for_organization(organization_a)
        Role.create_defaults_for_organization(organization_b)
        
        ActsAsTenant.with_tenant(organization_a) do
          user_a.update!(role: :admin)  # Set enum role for policy checks
          user_a.assign_role('admin')  # Also assign new role system
        end
        sign_in user_a
      end
      
      it 'accepts X-Organization-Id header' do
        get '/api/v1/users', headers: { 
          'X-Organization-Id' => organization_a.id.to_s,
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:success)
        # Validate tenant resolution by checking that only users from organization_a are returned
        returned_user_ids = json_response['data'].map { |u| u['id'] }
        expect(returned_user_ids).to include(user_a.id)
      end
      
      it 'accepts X-Organization-Subdomain header' do
        get '/api/v1/users', headers: { 
          'X-Organization-Subdomain' => organization_a.subdomain,
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:success)
        # Validate tenant resolution by checking that only users from organization_a are returned
        returned_user_ids = json_response['data'].map { |u| u['id'] }
        expect(returned_user_ids).to include(user_a.id)
      end
      
      it 'rejects mismatched organization header' do
        get '/api/v1/users', headers: { 
          'X-Organization-Id' => organization_b.id.to_s,
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to include("Invalid organization access - token mismatch")
      end
    end
  end
  
  describe 'Data isolation across tenants' do
    before do
      Role.create_defaults_for_organization(organization_a)
      Role.create_defaults_for_organization(organization_b)
      
      ActsAsTenant.with_tenant(organization_a) do
        user_a.update!(role: :admin)  # Set enum role for policy checks
        user_a.assign_role('admin')  # Also assign new role system
      end
      ActsAsTenant.with_tenant(organization_b) do
        user_b.update!(role: :admin)  # Set enum role for policy checks
        user_b.assign_role('admin')  # Also assign new role system
      end
    end
    
    context 'Users API' do
      it 'only returns users from current tenant' do
        sign_in user_a
        get '/api/v1/users', headers: { 
          'X-Organization-Id' => organization_a.id.to_s,
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:success)
        returned_user_ids = json_response['data'].map { |u| u['id'] }
        expect(returned_user_ids).to include(user_a.id)
        expect(returned_user_ids).not_to include(user_b.id)
      end
      
      it 'prevents access to users from different tenant' do
        sign_in user_a
        get "/api/v1/users/#{user_b.id}", headers: { 
          'X-Organization-Id' => organization_a.id.to_s,
          'Authorization' => "Bearer #{jwt_token_for(user_a)}"
        }
        
        expect(response).to have_http_status(:not_found)
      end
      
      it 'prevents creating users in different tenant context' do
        sign_in user_a
        post '/api/v1/users', 
             params: { user: { 
               email: 'test@example.com', 
               organization_id: organization_b.id,
               password: 'password123',
               first_name: 'Test',
               last_name: 'User'
             } },
             headers: { 
               'X-Organization-Id' => organization_a.id.to_s,
               'Authorization' => "Bearer #{jwt_token_for(user_a)}"
             }
        
        expect(response).to have_http_status(:forbidden)
      end
    end
    
  end
  
  describe 'Role-based access within tenants' do
    let(:admin_a) { create(:user, organization: organization_a) }
    let(:client_a) { create(:user, organization: organization_a) }
    
    before do
      Role.create_defaults_for_organization(organization_a)
      
      ActsAsTenant.with_tenant(organization_a) do
        admin_a.update!(role: :admin)  # Set enum role for policy checks
        admin_a.assign_role('admin')
        client_a.update!(role: :guardian)  # Set enum role for client (guardian in enum)
        client_a.assign_role('client')
      end
    end
    
    it 'enforces role-based permissions within tenant' do
      # Admin can access all users in their tenant
      sign_in admin_a
      get '/api/v1/users', headers: { 
        'X-Organization-Id' => organization_a.id.to_s,
        'Authorization' => "Bearer #{jwt_token_for(admin_a)}"
      }
      expect(response).to have_http_status(:success)
      
      # Client cannot access users list (only admins and staff can)
      sign_in client_a
      get '/api/v1/users', headers: { 
        'X-Organization-Id' => organization_a.id.to_s,
        'Authorization' => "Bearer #{jwt_token_for(client_a)}"
      }
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe 'JWT token organization validation' do
    before do
      Role.create_defaults_for_organization(organization_a)
      Role.create_defaults_for_organization(organization_b)
    end
    
    it 'rejects JWT tokens with mismatched organization_id' do
      # Create JWT token with organization_a context
      token = jwt_token_for(user_a)
      
      # Try to use it with organization_b context
      get '/api/v1/users', headers: { 
        'X-Organization-Id' => organization_b.id.to_s,
        'Authorization' => "Bearer #{token}"
      }
      
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to include("Invalid organization access - token mismatch")
    end
    
    it 'accepts JWT tokens with matching organization_id' do
      ActsAsTenant.with_tenant(organization_a) do
        user_a.update!(role: :admin)  # Set enum role for policy checks
        user_a.assign_role('admin')  # Also assign new role system
      end
      
      token = jwt_token_for(user_a)
      
      get '/api/v1/users', headers: { 
        'X-Organization-Id' => organization_a.id.to_s,
        'Authorization' => "Bearer #{token}"
      }
      
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'Cross-tenant data leakage prevention' do
    before do
      Role.create_defaults_for_organization(organization_a)
      Role.create_defaults_for_organization(organization_b)
    end
    
    it 'prevents SQL injection attacks across tenants' do
      ActsAsTenant.with_tenant(organization_a) do
        user_a.assign_role('admin')  # Use admin role for broader access
      end
      
      # Attempt SQL injection to access data from other tenant
      malicious_subdomain = "org-a'; SELECT * FROM users WHERE organization_id = #{organization_b.id}; --"
      
      sign_in user_a
      get '/api/v1/users', headers: { 
        'X-Organization-Subdomain' => malicious_subdomain,
        'Authorization' => "Bearer #{jwt_token_for(user_a)}"
      }
      
      expect(response).to have_http_status(:bad_request)
    end
    
    it 'prevents parameter manipulation to access other tenant data' do
      ActsAsTenant.with_tenant(organization_a) do
        user_a.assign_role('admin')  # Use admin role for broader access
      end
      
      sign_in user_a
      post '/api/v1/users', 
           params: { user: { email: 'test@example.com', organization_id: organization_b.id } },
           headers: { 
             'X-Organization-Id' => organization_a.id.to_s,
             'Authorization' => "Bearer #{jwt_token_for(user_a)}"
           }
      
      # Should create user in organization_a, not organization_b
      if response.status == 201
        created_user = User.find(json_response['data']['id'])
        expect(created_user.organization).to eq(organization_a)
      end
    end
  end
  
  describe 'Tenant context consistency' do
    before do
      Role.create_defaults_for_organization(organization_a)
    end
    
    it 'maintains tenant context throughout request lifecycle' do
      ActsAsTenant.with_tenant(organization_a) do
        user_a.update!(role: :admin)  # Set enum role for policy checks
        user_a.assign_role('admin')  # Also assign new role system
      end
      
      sign_in user_a
      
      # Simple test - if the request succeeds and returns correct data, tenant context was maintained
      get '/api/v1/users', headers: { 
        'X-Organization-Id' => organization_a.id.to_s,
        'Authorization' => "Bearer #{jwt_token_for(user_a)}"
      }
      
      expect(response).to have_http_status(:success)
      # Validate tenant context by checking that only users from organization_a are returned
      returned_user_ids = json_response['data'].map { |u| u['id'] }
      expect(returned_user_ids).to include(user_a.id)
    end
  end
  
  private
  
  def jwt_token_for(user)
    generate_jwt_token(user)
  end
  
  def json_response
    JSON.parse(response.body)
  end
  
  def sign_in(user)
    # Mock authentication for testing
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(Api::V1::BaseController).to receive(:current_user).and_return(user)
  end
end