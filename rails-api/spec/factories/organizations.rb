FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:subdomain) { |n| "org#{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    phone { "+1-555-0123" }
    address { "123 Main St, Test City, TC 12345" }
    settings do
      {
        timezone: "America/New_York",
        booking_window_days: 30,
        cancellation_policy_hours: 24,
        default_session_duration: 60,
        currency: "USD",
        language: "en"
      }
    end

    trait :rayces do
      name { "Rayces - Centro de Desarrollo Integral" }
      subdomain { "rayces" }
      email { "admin@rayces.com" }
      phone { "+54 11 4567-8900" }
      address { "Av. Santa Fe 1234, C1060AAB Buenos Aires, Argentina" }
      settings do
        {
          timezone: "America/Argentina/Buenos_Aires",
          booking_window_days: 30,
          cancellation_policy_hours: 24,
          default_session_duration: 50,
          currency: "ARS",
          language: "es-AR"
        }
      end
    end
  end
end