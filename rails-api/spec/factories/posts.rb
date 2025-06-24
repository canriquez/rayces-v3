FactoryBot.define do
  factory :post do
    post_id { 1 }
    hash_id { "MyString" }
    source { "MyString" }
    metadata { "MyText" }
    filename { "MyString" }
  end
end
