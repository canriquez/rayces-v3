# app/serializers/student_serializer.rb
class StudentSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :full_name, :date_of_birth,
             :gender, :grade_level, :active, :created_at, :updated_at
  
  belongs_to :parent, serializer: UserSerializer
  
  attribute :age, if: :can_calculate_age?
  attribute :medical_notes, if: :can_view_private_info?
  attribute :educational_notes, if: :can_view_private_info?
  attribute :emergency_contacts, if: :can_view_private_info?
  
  def full_name
    object.full_name
  end
  
  def age
    object.age
  end
  
  def can_calculate_age?
    object.date_of_birth.present?
  end
  
  def can_view_private_info?
    return true unless current_user
    
    # Only the parent, professionals with appointments, staff, and admins can view private info
    current_user.admin? || 
    current_user.staff? || 
    object.parent_id == current_user.id ||
    (current_user.professional? && object.appointments.where(professional_id: current_user.id).exists?)
  end
  
  private
  
  def current_user
    instance_options[:current_user] || scope
  end
end