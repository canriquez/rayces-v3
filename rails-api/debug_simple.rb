#!/usr/bin/env ruby

# Simple debug script to test JWT generation
require_relative 'config/environment'

puts "=== Simple JWT Test ==="

# Create organization and user like in the test
org = FactoryBot.create(:organization)
puts "Created organization: #{org.id} - #{org.name} (#{org.subdomain})"

user = nil
ActsAsTenant.with_tenant(org) do
  user = FactoryBot.create(:user, organization: org)
  puts "Created user: #{user.id} - #{user.email} (org: #{user.organization_id})"
end

# Test JWT secret key method from ApplicationController
class TestController < ApplicationController
  def test_jwt_secret
    jwt_secret_key
  end
end

controller = TestController.new
secret = controller.test_jwt_secret
puts "JWT secret available: #{secret.present?}"

# Test manual JWT generation
require 'jwt'

payload = {
  user_id: user.id,
  organization_id: user.organization_id,
  email: user.email,
  jti: user.jti,
  exp: 24.hours.from_now.to_i,
  iat: Time.current.to_i
}

token = JWT.encode(payload, secret)
puts "Generated JWT token: #{token[0..50]}..."

# Test decoding
decoded = JWT.decode(token, secret).first
puts "Decoded payload: #{decoded}"

# Test organization access
puts "User can access organization: #{user.can_access_organization?(org)}"

puts "=== End Test ==="