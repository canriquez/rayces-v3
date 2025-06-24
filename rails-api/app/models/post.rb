class Post < ApplicationRecord
  has_many :likes
  has_many :liking_users, through: :likes, source: :user
end
