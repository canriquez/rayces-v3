# Tenant Helpers for RSpec Multi-tenant Tests
# This module provides helpers for managing multi-tenant context in tests

module TenantHelpers
  # Execute a block within a specific tenant context
  def with_tenant(organization)
    ActsAsTenant.with_tenant(organization) do
      yield
    end
  end

  # Set the current tenant context explicitly
  def set_tenant_context(organization)
    ActsAsTenant.current_tenant = organization
  end

  # Clear the current tenant context
  def clear_tenant_context
    ActsAsTenant.current_tenant = nil
  end

  # Reset tenant context for cleanup
  def reset_tenant_context
    ActsAsTenant.current_tenant = nil
  end

  # Create a UserContext for Pundit policies
  def user_context(user, organization = nil)
    org = organization || user.organization
    UserContext.new(user, org)
  end

  # Create factory records with proper tenant context
  def create_with_tenant(organization, factory_name, **attributes)
    ActsAsTenant.with_tenant(organization) do
      create(factory_name, **attributes, organization: organization)
    end
  end

  # Build factory records with proper tenant context
  def build_with_tenant(organization, factory_name, **attributes)
    ActsAsTenant.with_tenant(organization) do
      build(factory_name, **attributes, organization: organization)
    end
  end

  # Test authorization with user context
  def authorize_user(user, record, action = nil)
    context = user_context(user)
    policy = Pundit.policy(context, record)
    
    if action
      policy.public_send("#{action}?")
    else
      policy.show?
    end
  end

  # Create multiple organizations for cross-tenant testing
  def create_organizations(count = 2)
    (1..count).map do |i|
      create(:organization, 
        name: "Test Organization #{i}",
        subdomain: "test-org-#{i}"
      )
    end
  end

  # Create users in different organizations for cross-tenant testing
  def create_cross_tenant_users(organizations = nil)
    orgs = organizations || create_organizations(2)
    
    orgs.map do |org|
      ActsAsTenant.with_tenant(org) do
        create(:user, organization: org)
      end
    end
  end

  # Helper for testing tenant isolation
  def expect_tenant_isolation(user1, user2, record_factory, &block)
    org1 = user1.organization
    org2 = user2.organization
    
    # Create record in first tenant
    record = nil
    ActsAsTenant.with_tenant(org1) do
      record = create(record_factory, user: user1, organization: org1)
    end
    
    # Try to access from second tenant
    ActsAsTenant.with_tenant(org2) do
      yield(record, user2)
    end
  end

  # Helper for testing cross-tenant access prevention
  def expect_cross_tenant_access_denied(user, foreign_record, &block)
    original_tenant = ActsAsTenant.current_tenant
    
    # Ensure we're in the user's tenant context
    ActsAsTenant.with_tenant(user.organization) do
      # Attempt to access record from different tenant
      yield(foreign_record)
    end
  ensure
    ActsAsTenant.current_tenant = original_tenant
  end

  # Helper for setting organization headers in requests
  def organization_headers(organization)
    {
      'X-Organization-Id' => organization.id.to_s,
      'X-Organization-Subdomain' => organization.subdomain
    }
  end

  # Helper for setting organization headers by subdomain
  def subdomain_headers(subdomain)
    {
      'X-Organization-Subdomain' => subdomain
    }
  end

  # Helper for making requests with organization context
  def make_request_with_organization(method, path, organization, user = nil, params = {})
    headers = organization_headers(organization)
    headers.merge!(auth_headers(user)) if user
    
    send(method, path, params: params, headers: headers)
  end

  # Helper for testing subdomain resolution
  def with_subdomain(subdomain)
    old_subdomain = request.subdomain if defined?(request)
    
    # Mock subdomain for testing
    allow(request).to receive(:subdomain).and_return(subdomain) if defined?(request)
    
    yield
  ensure
    allow(request).to receive(:subdomain).and_return(old_subdomain) if defined?(request) && old_subdomain
  end

  # Helper for testing tenant context consistency
  def expect_consistent_tenant_context(organization)
    expect(ActsAsTenant.current_tenant).to eq(organization)
  end

  # Helper for database cleanup with tenant context
  def clean_database_with_tenant_context
    # Clear tenant context before cleanup
    original_tenant = ActsAsTenant.current_tenant
    ActsAsTenant.current_tenant = nil
    
    # Perform database cleanup
    DatabaseCleaner.clean
    
    # Restore tenant context
    ActsAsTenant.current_tenant = original_tenant
  end
end