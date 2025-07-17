# app/serializers/appointment_serializer.rb
class AppointmentSerializer < ActiveModel::Serializer
  attributes :id, :scheduled_at, :ends_at, :duration_minutes, :state,
             :notes, :price, :uses_credits, :credits_used,
             :created_at, :updated_at
  
  belongs_to :professional, serializer: UserSerializer
  belongs_to :client, serializer: UserSerializer  
  belongs_to :student, if: :has_student?
  
  attribute :cancellation_reason, if: :is_cancelled?
  attribute :cancelled_at, if: :is_cancelled?
  belongs_to :cancelled_by, serializer: UserSerializer, if: :is_cancelled?
  
  def ends_at
    object.ends_at
  end
  
  def has_student?
    object.student.present?
  end
  
  def is_cancelled?
    object.cancelled?
  end
  
  def cancellation_reason
    object.cancellation_reason if can_view_sensitive_info?
  end
  
  def notes
    object.notes if can_view_notes?
  end
  
  def can_view_sensitive_info?
    return true unless current_user
    
    # Professionals, clients involved, staff, and admins can view sensitive info
    current_user.admin? || 
    current_user.staff? || 
    object.professional_id == current_user.id ||
    object.client_id == current_user.id
  end
  
  def can_view_notes?
    return true unless current_user
    
    # Only professionals involved and admins can view notes
    current_user.admin? || object.professional_id == current_user.id
  end
  
  private
  
  def current_user
    instance_options[:current_user] || scope
  end
end