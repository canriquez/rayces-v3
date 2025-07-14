# spec/support/jwt_helpers.rb
module JwtHelpers
  def generate_jwt_token(user)
    payload = {
      sub: user.id,
      organization_id: user.organization_id,
      role: user.role,
      jti: user.jti,
      iat: Time.current.to_i,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
  end

  def auth_headers(user)
    token = generate_jwt_token(user)
    { 'Authorization' => "Bearer #{token}" }
  end

  def host_for_organization(organization)
    "#{organization.subdomain}.example.com"
  end

  def sign_in_with_jwt(user)
    @current_user = user
    @auth_headers = auth_headers(user)
    @organization_host = host_for_organization(user.organization)
  end

  # Override HTTP methods to automatically include auth headers when @auth_headers is set
  def get(path, **args)
    args[:headers] = (@auth_headers || {}).merge(args[:headers] || {})
    super(path, **args)
  end

  def post(path, **args)
    args[:headers] = (@auth_headers || {}).merge(args[:headers] || {})
    super(path, **args)
  end

  def patch(path, **args)
    args[:headers] = (@auth_headers || {}).merge(args[:headers] || {})
    super(path, **args)
  end

  def put(path, **args)
    args[:headers] = (@auth_headers || {}).merge(args[:headers] || {})
    super(path, **args)
  end

  def delete(path, **args)
    args[:headers] = (@auth_headers || {}).merge(args[:headers] || {})
    super(path, **args)
  end

  def create_expired_jwt_token(user)
    payload = {
      sub: user.id,
      organization_id: user.organization_id,
      role: user.role,
      jti: user.jti,
      iat: 2.hours.ago.to_i,
      exp: 1.hour.ago.to_i # Expired
    }
    JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key)
  end

  def create_invalid_jwt_token
    payload = {
      sub: 999999,
      organization_id: 999999,
      role: 'admin',
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, 'wrong_secret_key')
  end
end

RSpec.configure do |config|
  config.include JwtHelpers, type: :request
  config.include JwtHelpers, type: :controller
end