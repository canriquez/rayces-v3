# spec/support/sidekiq_test.rb
# Ensure Sidekiq is in test mode
require 'sidekiq/testing'
Sidekiq::Testing.fake!

# Clear client middleware in test environment to avoid errors
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.clear
  end
end

# Helper to process Sidekiq jobs in tests
module SidekiqTestHelper
  def process_sidekiq_jobs
    Sidekiq::Worker.drain_all
  end
end

RSpec.configure do |config|
  config.include SidekiqTestHelper
  
  # Clear job queues before each test
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end