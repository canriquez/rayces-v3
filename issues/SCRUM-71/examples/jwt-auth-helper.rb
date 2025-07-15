# JWT Authentication Helper for RSpec Tests
# This helper provides methods to generate JWT tokens for testing

module JwtHelpers
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

    JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
  end

  def decode_jwt_token(token)
    JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
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
end