# Example: Devise JWT Configuration
# This example shows how to configure devise-jwt in Rails initializer

# config/initializers/devise.rb
Devise.setup do |config|
  # The secret key used by Devise
  config.secret_key = Rails.application.credentials.devise_secret_key
  
  # Configure the e-mail address which will be shown in Devise::Mailer
  config.mailer_sender = 'noreply@rayces.com'
  
  # JWT configuration
  config.jwt do |jwt|
    # Secret key for encoding/decoding JWT tokens
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key!
    
    # Dispatch requests - endpoints that should return JWT tokens
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/login$}],
      ['POST', %r{^/api/v1/signup$}],
      ['POST', %r{^/api/v1/auth/login$}],
      ['POST', %r{^/api/v1/auth/signup$}]
    ]
    
    # Revocation requests - endpoints that should revoke JWT tokens
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/logout$}],
      ['DELETE', %r{^/api/v1/auth/logout$}]
    ]
    
    # Token expiration time
    jwt.expiration_time = 24.hours.to_i
    
    # JWT token audience (optional)
    # jwt.aud = 'rayces-api'
    
    # JWT token issuer (optional)
    # jwt.iss = 'rayces'
  end
  
  # Multi-tenancy configuration
  config.request_keys = [:subdomain]
  config.scoped_views = true
  
  # Database authenticatable
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  
  # Password configuration
  config.password_length = 8..128
  config.email_regexp = URI::MailTo::EMAIL_REGEXP
  
  # Lockable configuration
  config.lock_strategy = :failed_attempts
  config.unlock_keys = [:email]
  config.unlock_strategy = :both
  config.maximum_attempts = 5
  config.unlock_in = 1.hour
  config.last_attempt_warning = true
  
  # Rememberable
  config.remember_for = 2.weeks
  config.extend_remember_period = false
  
  # Validatable
  config.validate_on_invite = true
  
  # Confirmable
  config.allow_unconfirmed_access_for = 2.days
  config.confirm_within = 3.days
  config.reconfirmable = true
  
  # Timeoutable
  config.timeout_in = 30.minutes
  
  # HTTP authentication
  config.http_authenticatable = [:database]
  config.http_authenticatable_on_xhr = true
  config.http_authentication_realm = 'Application'
  
  # Skip session storage for API tokens
  config.skip_session_storage = [:http_auth, :token_auth]
  
  # Hotwire/Turbo configuration (if using Turbo)
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end