# 00_acts_as_tenant_test_override.rb
# Test environment configuration for acts_as_tenant

if Rails.env.test?
  # Set require_tenant to false in test environment
  ActsAsTenant.configure do |config|
    config.require_tenant = false
  end
end