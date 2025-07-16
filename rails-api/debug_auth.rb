#!/usr/bin/env ruby

# Debug script to understand authentication flow
require_relative 'config/environment'

puts "=== Debug Authentication Flow ==="

# Create organization and user like in the test
org = FactoryBot.create(:organization)
puts "Created organization: #{org.id} - #{org.name} (#{org.subdomain})"

user = nil
ActsAsTenant.with_tenant(org) do
  user = FactoryBot.create(:user, organization: org)
  puts "Created user: #{user.id} - #{user.email} (org: #{user.organization_id})"
end

# Test JWT token generation
require_relative 'spec/support/authentication_helpers'
require_relative 'spec/support/jwt_helpers'

class DebugHelper
  include AuthenticationHelpers
  include JwtHelpers
end

debug = DebugHelper.new

# Generate JWT token
token = debug.generate_jwt_token(user)
puts "Generated JWT token: #{token[0..50]}..."

# Decode JWT token
payload = debug.decode_jwt_token(token)
puts "Decoded JWT payload: #{payload}"

# Check JWT secret
secret = debug.send(:jwt_secret_key)
puts "JWT secret key present: #{secret.present?}"
puts "JWT secret key source: #{
  if Rails.application.credentials.devise_jwt_secret_key
    'devise_jwt_secret_key'
  elsif Rails.application.credentials.secret_key_base
    'secret_key_base'
  elsif ENV['SECRET_KEY_BASE']
    'ENV[SECRET_KEY_BASE]'
  else
    'NONE'
  end
}"

# Test organization access
puts "User can access organization: #{user.can_access_organization?(org)}"

# Test tenant context
ActsAsTenant.current_tenant = org
puts "Current tenant set to: #{ActsAsTenant.current_tenant&.id}"

puts "=== End Debug ==="