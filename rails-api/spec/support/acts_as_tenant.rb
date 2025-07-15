# spec/support/acts_as_tenant.rb
# Configure acts_as_tenant for testing

RSpec.configure do |config|
  config.before(:suite) do
    # Clean database and create default organizations for testing
    DatabaseCleaner.clean_with(:truncation)
    
    # Create test organizations that will be available throughout the test suite
    $default_organization = FactoryBot.create(:organization, 
      name: 'Test Organization',
      subdomain: 'test-org',
      email: 'test@example.com',
      active: true
    )
    
    $secondary_organization = FactoryBot.create(:organization,
      name: 'Secondary Organization', 
      subdomain: 'secondary-org',
      email: 'secondary@example.com',
      active: true
    )
    
    # Create a third organization for more complex tenant isolation tests
    $tertiary_organization = FactoryBot.create(:organization,
      name: 'Tertiary Organization',
      subdomain: 'tertiary-org', 
      email: 'tertiary@example.com',
      active: true
    )
    
    Rails.logger.info "[TEST SETUP] Created test organizations: #{$default_organization.subdomain}, #{$secondary_organization.subdomain}, #{$tertiary_organization.subdomain}"
  end
  
  config.before(:each) do |example|
    # Set up tenant context based on test type
    if example.metadata[:type] == :request
      # For request specs, use test_tenant to simulate HTTP request context
      ActsAsTenant.test_tenant = $default_organization
    else
      # For model/unit specs, use current_tenant directly
      ActsAsTenant.current_tenant = $default_organization
    end
  end
  
  config.after(:each) do |example|
    # Clear tenant context after each test to prevent test contamination
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
  end
  
  # Helper methods for multi-tenant testing
  config.include(Module.new do
    # Helper to test within a specific tenant context
    def with_tenant(organization)
      original_tenant = ActsAsTenant.current_tenant
      ActsAsTenant.current_tenant = organization
      yield
    ensure
      ActsAsTenant.current_tenant = original_tenant
    end
    
    # Helper to test without any tenant (for admin operations)
    def without_tenant
      original_tenant = ActsAsTenant.current_tenant
      ActsAsTenant.current_tenant = nil
      ActsAsTenant.without_tenant do
        yield
      end
    ensure
      ActsAsTenant.current_tenant = original_tenant
    end
    
    # Helper to get current tenant in tests
    def current_tenant
      ActsAsTenant.current_tenant
    end
    
    # Helper to create tenant-scoped objects in tests
    def create_in_tenant(factory_name, organization = nil, **attributes)
      org = organization || $default_organization
      with_tenant(org) do
        FactoryBot.create(factory_name, organization: org, **attributes)
      end
    end
    
    # Helper to verify tenant isolation
    def verify_tenant_isolation(model_class, organization1 = nil, organization2 = nil)
      org1 = organization1 || $default_organization
      org2 = organization2 || $secondary_organization
      
      # Create records in different tenants
      record1 = with_tenant(org1) { yield(org1) }
      record2 = with_tenant(org2) { yield(org2) }
      
      # Verify isolation
      with_tenant(org1) do
        expect(model_class.all).to include(record1)
        expect(model_class.all).not_to include(record2)
      end
      
      with_tenant(org2) do
        expect(model_class.all).to include(record2)
        expect(model_class.all).not_to include(record1)
      end
    end
  end)
end

# Shared examples for multi-tenant models
RSpec.shared_examples 'a tenant-scoped model' do
  it 'is scoped to current tenant' do
    model1 = create_in_tenant(described_class.model_name.singular, $default_organization)
    model2 = create_in_tenant(described_class.model_name.singular, $secondary_organization)
    
    with_tenant($default_organization) do
      expect(described_class.all).to include(model1)
      expect(described_class.all).not_to include(model2)
    end
    
    with_tenant($secondary_organization) do
      expect(described_class.all).to include(model2)
      expect(described_class.all).not_to include(model1)
    end
  end
  
  it 'belongs to an organization' do
    expect(described_class.new).to respond_to(:organization)
    expect(described_class.new).to respond_to(:organization_id)
  end
  
  it 'validates organization presence' do
    model = build(described_class.model_name.singular, organization: nil)
    expect(model).not_to be_valid
    expect(model.errors[:organization]).to be_present
  end
end

# Shared examples for tenant isolation in controllers
RSpec.shared_examples 'tenant-isolated API endpoint' do |method, path_template|
  it 'prevents cross-tenant access' do
    # Create data in different organizations
    user1 = create_in_tenant(:user, $default_organization)
    user2 = create_in_tenant(:user, $secondary_organization)
    
    # Generate JWT for user1
    jwt_token = JWT.encode(
      { 
        sub: user1.id,
        organization_id: $default_organization.id,
        exp: 1.hour.from_now.to_i
      },
      Rails.application.credentials.secret_key_base,
      'HS256'
    )
    
    # Try to access user2's organization data with user1's token
    headers = {
      'Authorization' => "Bearer #{jwt_token}",
      'X-Organization-Subdomain' => $secondary_organization.subdomain
    }
    
    # This should fail with 403 Forbidden
    send(method, path_template, headers: headers)
    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body)['error']).to include('organization access')
  end
end