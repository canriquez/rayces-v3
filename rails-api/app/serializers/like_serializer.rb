class LikeSerializer < ActiveModel::Serializer
  attributes :id, :created_at
  
  belongs_to :user
  belongs_to :post
  
  # Let ActiveModel::Serializers handle the association automatically
end