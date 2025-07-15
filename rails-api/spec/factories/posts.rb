FactoryBot.define do
  factory :post do
    post_id { 1 }
    hash_id { "MyString" }
    source { "MyString" }
    metadata { "MyText" }
    filename { "MyString" }
    content { "Test post content" }
    association :user
    
    # Set organization from user to maintain consistency
    after(:build) do |post, evaluator|
      post.organization = post.user.organization
    end
  end
end
