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
    unless auth_header
      return unauthorized_response
    end

    token = auth_header.split(' ').last

    begin
      payload = verify_token(token)
      puts "response payload: #{payload.inspect}"
      env['google_user'] = payload
      @app.call(env)
    rescue Google::Auth::IDTokens::VerificationError
      unauthorized_response
    end
  end

  private

  def verify_token(token)
    client_id = ENV['GOOGLE_CLIENT_ID']
    puts "verifying token with client ID: #{client_id}"
    Google::Auth::IDTokens.verify_oidc(token, aud: client_id)
  end

  def unauthorized_response
    [401, { 'Content-Type' => 'application/json' }, [{ error: 'Unauthorized' }.to_json]]
  end
end
