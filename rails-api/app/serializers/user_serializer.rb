# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :full_name, :phone,
             :role, :created_at, :updated_at
  
  belongs_to :organization, if: :include_organization?
  has_one :professional_profile, if: :is_professional?
  
  def full_name
    object.full_name
  end
  
  def include_organization?
    # Only include organization for admins or when specifically requested
    current_user&.admin? || instance_options[:include_organization]
  end
  
  def is_professional?
    object.professional?
  end
  
  private
  
  def current_user
    # Access current user from serialization context
    instance_options[:current_user] || scope
  end
end