FactoryBot.define do
  factory :like do
    # Don't auto-create associations - they need to be created within tenant context
    # user and post will be set by the test or other factories
    
    # Ensure like inherits organization from associations
    after(:build) do |like|
      # Set organization from existing associations, don't modify them
      like.organization ||= like.user&.organization || like.post&.organization || ActsAsTenant.current_tenant
    end
  end
end