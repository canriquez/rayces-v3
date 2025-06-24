class User < ApplicationRecord
  has_many :likes
  has_many :liked_posts, through: :likes, source: :post
  
  validates :email, presence: true, uniqueness: true
  validates :uid, presence: true, uniqueness: true
end
