# Authentication Helpers for RSpec Tests
# This helper provides methods to generate JWT tokens for testing

module AuthenticationHelpers
  def auth_headers(user)
    token = generate_jwt_token(user)
    { 
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def generate_jwt_token(user)
    # Include all necessary fields in JWT payload
    payload = {
      user_id: user.id,
      organization_id: user.organization_id,
      email: user.email,
      jti: user.jti,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i
    }

    JWT.encode(payload, jwt_secret_key)
  end

  def decode_jwt_token(token)
    JWT.decode(token, jwt_secret_key).first
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end

  def sign_in_with_jwt(user)
    # Set the Authorization header for the current test
    @jwt_token = generate_jwt_token(user)
    request.headers['Authorization'] = "Bearer #{@jwt_token}"
  end

  def current_jwt_payload
    return nil unless @jwt_token
    decode_jwt_token(@jwt_token)
  end

  # Helper method for making authenticated requests in tests
  def make_authenticated_request(method, path, user, params = {})
    send(method, path, params: params, headers: auth_headers(user))
  end

  # Helper method to test authentication failures
  def make_unauthenticated_request(method, path, params = {})
    send(method, path, params: params, headers: {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    })
  end

  # Helper method to test with expired tokens
  def generate_expired_jwt_token(user)
    payload = {
      user_id: user.id,
      organization_id: user.organization_id,
      email: user.email,
      jti: user.jti,
      exp: 1.hour.ago.to_i,  # Expired token
      iat: 2.hours.ago.to_i
    }

    JWT.encode(payload, jwt_secret_key)
  end

  def auth_headers_with_expired_token(user)
    token = generate_expired_jwt_token(user)
    { 
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  # Helper method to test with invalid tokens
  def auth_headers_with_invalid_token
    { 
      'Authorization' => "Bearer invalid.token.here",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  # Helper method to test with wrong secret key
  def generate_jwt_token_with_wrong_key(user)
    payload = {
      user_id: user.id,
      organization_id: user.organization_id,
      email: user.email,
      jti: user.jti,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i
    }

    JWT.encode(payload, "wrong-secret-key")
  end

  def auth_headers_with_wrong_key(user)
    token = generate_jwt_token_with_wrong_key(user)
    { 
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
  
  private
  
  def jwt_secret_key
    Rails.application.credentials.devise_jwt_secret_key || 
    Rails.application.credentials.secret_key_base || 
    ENV['SECRET_KEY_BASE']
  end
end