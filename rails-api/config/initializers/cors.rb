# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Configure origins based on environment
    if Rails.env.production?
      # In production, specify allowed origins
      origins ENV.fetch('ALLOWED_ORIGINS', 'https://app.rayces.com').split(',')
    else
      # In development, allow localhost with various ports
      origins /\Ahttp:\/\/localhost:\d+\z/, 
              /\Ahttp:\/\/127\.0\.0\.1:\d+\z/,
              /\Ahttp:\/\/.*\.localhost:\d+\z/  # Support subdomain-based tenancy
    end

    resource "*",
      headers: :any,
      expose: ['Authorization'], # Expose JWT token in responses
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true # Allow cookies and authorization headers
  end
  
  # Specific configuration for API routes
  allow do
    if Rails.env.production?
      origins ENV.fetch('ALLOWED_ORIGINS', 'https://app.rayces.com').split(',')
    else
      origins /\Ahttp:\/\/localhost:\d+\z/, 
              /\Ahttp:\/\/127\.0\.0\.1:\d+\z/,
              /\Ahttp:\/\/.*\.localhost:\d+\z/
    end

    resource "/api/*",
      headers: :any,
      expose: ['Authorization', 'Content-Type', 'Accept'], # JWT and content headers
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 86400 # Cache preflight requests for 24 hours
  end
  
  # Specific configuration for authentication endpoints
  allow do
    if Rails.env.production?
      origins ENV.fetch('ALLOWED_ORIGINS', 'https://app.rayces.com').split(',')
    else
      origins /\Ahttp:\/\/localhost:\d+\z/, 
              /\Ahttp:\/\/127\.0\.0\.1:\d+\z/,
              /\Ahttp:\/\/.*\.localhost:\d+\z/
    end

    resource "/auth/*",
      headers: :any,
      expose: ['Authorization', 'Content-Type'], # JWT tokens in auth responses
      methods: [:post, :delete, :options],
      credentials: true
  end
end