require 'googleauth'

class GoogleTokenVerifier
  def initialize(app)
    @app = app
    @excluded_paths = ['/up', '/welcome/index']
  end

  def call(env)
    request = Rack::Request.new(env)
    if @excluded_paths.include?(request.path)
      return @app.call(env)
    end

    auth_header = request.get_header('HTTP_AUTHORIZATION')
    
    # Handle missing, empty, or malformed authorization headers
    if auth_header.nil? || auth_header.strip.empty? || !auth_header.include?(' ')
      return @app.call(env) # Let ApplicationController handle missing/empty auth
    end

    token = auth_header.split(' ').last

    # Check if this looks like a JWT token (has 3 parts separated by dots)
    # JWT tokens have format: header.payload.signature
    if is_jwt_token?(token)
      # Skip Google verification for JWT tokens, let ApplicationController handle it
      return @app.call(env)
    end

    begin
      payload = verify_token(token)
      env['google_user'] = payload
      @app.call(env)
    rescue Google::Auth::IDTokens::VerificationError
      # Let ApplicationController handle the authentication failure
      @app.call(env)
    end
  end

  private

  def is_jwt_token?(token)
    # JWT tokens have exactly 3 parts separated by dots: header.payload.signature
    return false if token.nil? || token.empty?
    token.split('.').length == 3
  end

  def verify_token(token)
    client_id = ENV['GOOGLE_CLIENT_ID']
    Google::Auth::IDTokens.verify_oidc(token, aud: client_id)
  end

  def unauthorized_response
    [401, { 'Content-Type' => 'application/json' }, [{ error: 'Unauthorized' }.to_json]]
  end
end
