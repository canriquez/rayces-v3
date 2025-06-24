require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Ensure the custom middleware is loaded
require_relative '../app/middleware/google_token_verifier'

module YourRailsAppName
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Ensure custom middleware is autoloaded
    config.autoload_paths += %W(#{config.root}/app/middleware)

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.middleware.use GoogleTokenVerifier
    config.api_only = true
  end
end
