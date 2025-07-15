# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'database_cleaner/active_record'
require 'shoulda/matchers'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# Load support files for shared examples and helpers
Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # FactoryBot configuration
  config.include FactoryBot::Syntax::Methods

  # Include authentication helpers for all specs
  config.include AuthenticationHelpers

  # Include tenant helpers for all specs
  config.include TenantHelpers

  # JSON response helper for request specs
  config.include Module.new {
    def json_response
      JSON.parse(response.body)
    end
  }, type: :request

  # Additional helpers for request specs
  config.include Module.new {
    def expect_json_response(expected_keys = [])
      expect(response.content_type).to eq('application/json; charset=utf-8')
      
      if expected_keys.any?
        response_data = json_response
        expected_keys.each do |key|
          expect(response_data).to have_key(key.to_s)
        end
      end
    end

    def expect_unauthorized_response
      expect(response).to have_http_status(:unauthorized)
    end

    def expect_forbidden_response
      expect(response).to have_http_status(:forbidden)
    end

    def expect_not_found_response
      expect(response).to have_http_status(:not_found)
    end
  }, type: :request

  # Sidekiq testing configuration - disable Redis for tests
  require 'sidekiq/testing'
  Sidekiq::Testing.fake!

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  # Database Cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.allow_remote_database_url = true
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Multi-tenancy configuration for tests
  config.before(:suite) do
    # Create a default organization for all tests
    DatabaseCleaner.clean_with(:truncation)
    $default_organization = FactoryBot.create(:organization, 
      name: 'Test Organization',
      subdomain: 'test-org'
    )
  end
  
  config.before(:each) do
    # Set default tenant for each test unless explicitly managed
    ActsAsTenant.current_tenant = $default_organization unless ActsAsTenant.current_tenant
  end
  
  config.after(:each) do
    # Reset tenant context after each test for clean slate
    ActsAsTenant.current_tenant = nil
  end

  # Pundit configuration for testing
  # Note: Pundit test helpers are automatically available in policy specs
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
