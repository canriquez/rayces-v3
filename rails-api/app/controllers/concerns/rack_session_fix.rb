# app/controllers/concerns/rack_session_fix.rb
module RackSessionFix
  extend ActiveSupport::Concern

  # Rails 7 API mode doesn't include session middleware by default
  # Devise expects a session to be present, even if not used
  # This creates a fake session that satisfies Devise's requirements
  class FakeRackSession < Hash
    def enabled?
      false
    end

    def destroy
      clear
    end
  end

  included do
    before_action :set_fake_session

    private

    def set_fake_session
      request.env['rack.session'] ||= FakeRackSession.new
    end
  end
end