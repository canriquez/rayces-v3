class PostSerializer < ActiveModel::Serializer
  attributes :id, :post_id, :hash_id, :source, :metadata, :filename, :content, :created_at, :updated_at
  
  belongs_to :user
  has_many :likes
end