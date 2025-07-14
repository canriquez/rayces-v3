# app/serializers/professional_serializer.rb
class ProfessionalSerializer < ActiveModel::Serializer
  attributes :id, :title, :specialization, :bio, :session_duration_minutes,
             :active, :created_at, :updated_at
  
  belongs_to :user, serializer: UserSerializer
  
  attributes :license_number, :license_expiry, :hourly_rate, 
             :availability, :settings, if: :can_view_private_info?
  
  def display_name
    object.display_name
  end
  
  private
  
  def current_user
    instance_options[:current_user] || scope
  end
  
  def can_view_private_info?
    return true unless current_user
    
    # Only the professional themselves, staff, and admins can view private info
    current_user.admin? || 
    current_user.staff? || 
    object.user_id == current_user.id
  end
end