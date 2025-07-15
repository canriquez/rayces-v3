FactoryBot.define do
  factory :like do
    user
    post
    organization

    # Ensure all associations belong to the same organization
    after(:build) do |like|
      like.organization ||= like.user&.organization || like.post&.organization
      like.user.organization = like.organization if like.user
      like.post.organization = like.organization if like.post
      like.post.user = like.user if like.post && like.user
    end
  end
end