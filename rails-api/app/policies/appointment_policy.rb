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
    same_tenant? && (admin? || staff?) && record.draft?
  end
  
  # State transition policies
  def pre_confirm?
    same_tenant? && (admin? || staff? || record.professional_id == user.id)
  end
  
  def confirm?
    same_tenant? && (
      admin? || 
      staff? || 
      record.professional_id == user.id ||
      record.client_id == user.id  # Clients can confirm their own appointments
    )
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
      
      # Get the actual user object (UserContext wraps the user)
      actual_user = user.respond_to?(:user) ? user.user : user
      
      if actual_user.admin? || actual_user.staff?
        # Can see all appointments in organization
        appointments
      elsif actual_user.professional?
        # Can see their own appointments
        appointments.where(professional_id: actual_user.id)
      elsif actual_user.guardian? || actual_user.parent?
        # Can see appointments they booked
        appointments.where(client_id: actual_user.id)
      else
        appointments.none
      end
    end
  end
end