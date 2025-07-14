FactoryBot.define do
  factory :student do
    parent { build(:user, :guardian) }
    organization { parent.organization }
    sequence(:first_name) { |n| "Student#{n}" }
    last_name { "Child" }
    date_of_birth { 8.years.ago }
    gender { "male" }
    grade_level { "3rd Grade" }
    medical_notes { "No known allergies. Regular check-ups up to date." }
    educational_notes { "Bright student, enjoys learning. Needs support with focus." }
    emergency_contacts do
      [
        {
          name: "Emergency Contact",
          relationship: "Grandparent",
          phone: "+1-555-0999",
          email: "emergency@example.com"
        }
      ]
    end

    trait :with_special_needs do
      medical_notes { "Diagnosed with ADHD. Takes daily medication." }
      educational_notes { "Requires additional support with attention and organization." }
    end

    trait :preschooler do
      date_of_birth { 4.years.ago }
      grade_level { "Preschool" }
      medical_notes { "Developmental delay in speech. Receiving therapy." }
      educational_notes { "Very social child, responds well to visual cues." }
    end

    trait :teenager do
      date_of_birth { 14.years.ago }
      grade_level { "9th Grade" }
      medical_notes { "Dyslexia diagnosis. No other medical conditions." }
      educational_notes { "Excellent verbal comprehension, struggles with reading and writing." }
    end
  end
end