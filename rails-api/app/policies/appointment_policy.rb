# app/policies/appointment_policy.rb
class AppointmentPolicy < ApplicationPolicy
  def index?
    # Everyone can see appointments (scoped by role)
    true
  end
  
  def show?
    # Users can see appointments they're involved in
    same_tenant? && (
      admin? || 
      staff? || 
      record.professional_id == user.id ||
      record.client_id == user.id
    )
  end
  
  def create?
    # Parents, staff, professionals, and admins can create appointments
    parent? || staff? || professional? || admin?
  end
  
  def update?
    # Depends on the appointment state and user role
    return false unless same_tenant?
    
    case record.state
    when 'draft'
      # Draft appointments can be updated by creator, professional, admin, or staff
      record.client_id == user.id || record.professional_id == user.id || admin? || staff?
    when 'pre_confirmed', 'confirmed'
      # Only professionals, staff, and admins can update confirmed appointments
      record.professional_id == user.id || admin? || staff?
    when 'executed', 'cancelled'
      # Executed/cancelled appointments can only be updated by admins
      admin?
    else
      false
    end
  end
  
  def destroy?
    # Only draft appointments can be destroyed, and only by admins and staff
    (admin? || staff?) && record.draft?
  end
  
  # State transition policies
  def pre_confirm?
    same_tenant? && (admin? || staff? || record.professional_id == user.id)
  end
  
  def confirm?
    same_tenant? && (admin? || staff? || record.professional_id == user.id)
  end
  
  def execute?
    same_tenant? && (admin? || record.professional_id == user.id)
  end
  
  def cancel?
    return false unless same_tenant?
    
    case record.state
    when 'draft', 'pre_confirmed'
      # Can be cancelled by client, professional, staff, or admin
      record.client_id == user.id || 
      record.professional_id == user.id || 
      admin? || 
      staff?
    when 'confirmed'
      # Confirmed appointments need staff or admin approval to cancel
      admin? || staff?
    else
      false
    end
  end
  
  class Scope < Scope
    def resolve
      appointments = tenant_scope
      
      case user.role
      when 'admin', 'staff'
        # Can see all appointments in organization
        appointments
      when 'professional'
        # Can see their own appointments
        appointments.where(professional_id: user.id)
      when 'parent'
        # Can see appointments they booked
        appointments.where(client_id: user.id)
      else
        appointments.none
      end
    end
  end
end