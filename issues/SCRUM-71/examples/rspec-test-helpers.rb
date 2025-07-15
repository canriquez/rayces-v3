# RSpec Test Helpers for Authentication and Multi-tenancy
# This module provides comprehensive test helpers for the Rails application

module RSpecTestHelpers
  # JSON response helper for request specs
  def json_response
    JSON.parse(response.body)
  end

  # Authentication helpers
  def auth_headers(user)
    token = generate_jwt_token(user)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      organization_id: user.organization_id,
      email: user.email,
      jti: user.jti,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i
    }

    JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
  end

  # Tenant helpers
  def with_tenant(organization)
    ActsAsTenant.with_tenant(organization) do
      yield
    end
  end

  def set_tenant_context(organization)
    ActsAsTenant.current_tenant = organization
  end

  def clear_tenant_context
    ActsAsTenant.current_tenant = nil
  end

  # Pundit helpers
  def user_context(user, organization = nil)
    org = organization || user.organization
    UserContext.new(user, org)
  end

  def authorize_user(user, record, action = nil)
    context = user_context(user)
    policy = Pundit.policy(context, record)
    
    if action
      policy.public_send("#{action}?")
    else
      policy.show?
    end
  end

  # Factory helpers with tenant context
  def create_with_tenant(organization, factory_name, *args)
    ActsAsTenant.with_tenant(organization) do
      create(factory_name, *args, organization: organization)
    end
  end

  def build_with_tenant(organization, factory_name, *args)
    ActsAsTenant.with_tenant(organization) do
      build(factory_name, *args, organization: organization)
    end
  end

  # Request helpers
  def make_authenticated_request(method, path, user, params = {})
    send(method, path, params: params, headers: auth_headers(user))
  end

  def expect_json_response(expected_keys = [])
    expect(response.content_type).to eq('application/json; charset=utf-8')
    
    if expected_keys.any?
      response_data = json_response
      expected_keys.each do |key|
        expect(response_data).to have_key(key.to_s)
      end
    end
  end

  # Error testing helpers
  def expect_unauthorized_response
    expect(response).to have_http_status(:unauthorized)
  end

  def expect_forbidden_response
    expect(response).to have_http_status(:forbidden)
  end

  def expect_not_found_response
    expect(response).to have_http_status(:not_found)
  end

  # Database cleanup helpers
  def clean_database
    DatabaseCleaner.clean
  end

  def reset_tenant_context
    ActsAsTenant.current_tenant = nil
  end
end