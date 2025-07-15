# app/models/concerns/user_context.rb
# UserContext class for Pundit integration in multi-tenant environment
# This provides a context object that includes both user and organization information

class UserContext
  attr_reader :user, :organization
  
  def initialize(user, organization = nil)
    @user = user
    @organization = organization || user&.organization
  end
  
  # Delegate common user methods for convenience
  delegate :id, :email, :full_name, :first_name, :last_name, to: :user, allow_nil: true
  
  # Role checking methods that work with both enum and new role system
  def admin?
    user&.enhanced_admin?
  end
  
  def professional?
    user&.enhanced_professional?
  end
  
  def secretary?
    user&.enhanced_secretary?
  end
  
  def client?
    user&.enhanced_client?
  end
  
  def staff?
    user&.enhanced_secretary? # staff maps to secretary in new system
  end
  
  def guardian?
    user&.enhanced_client? # guardian maps to client in new system
  end
  
  def parent?
    guardian?
  end
  
  # Capability checking methods
  def can_manage_organization?
    user&.can_manage_organization?
  end
  
  def can_manage_appointments?
    user&.can_manage_appointments?
  end
  
  def can_book_appointments?
    user&.can_book_appointments?
  end
  
  # Organization access validation
  def can_access_organization?(target_organization)
    user&.can_access_organization?(target_organization)
  end
  
  def super_admin?
    user&.super_admin?
  end
  
  # Role management methods
  def has_role?(role_key)
    user&.has_role?(role_key)
  end
  
  def role_keys
    user&.role_keys || []
  end
  
  def primary_role
    user&.primary_role
  end
  
  # Organization context methods
  def organization_id
    organization&.id
  end
  
  def organization_name
    organization&.name
  end
  
  def organization_subdomain
    organization&.subdomain
  end
  
  def same_organization?(other_organization)
    organization == other_organization
  end
  
  def current_tenant
    organization
  end
  
  # Presence checking
  def present?
    user.present?
  end
  
  def blank?
    user.blank?
  end
  
  def nil?
    user.nil?
  end
  
  # Comparison methods
  def ==(other)
    if other.is_a?(UserContext)
      user == other.user && organization == other.organization
    elsif other.is_a?(User)
      user == other
    else
      false
    end
  end
  
  def eql?(other)
    self == other
  end
  
  def hash
    [user, organization].hash
  end
  
  # String representation
  def to_s
    if user
      "UserContext(#{user.full_name} @ #{organization&.name || 'No Organization'})"
    else
      "UserContext(No User)"
    end
  end
  
  def inspect
    "#<UserContext user=#{user&.id} organization=#{organization&.id}>"
  end
  
  # JSON representation for debugging
  def as_json(options = {})
    {
      user_id: user&.id,
      user_email: user&.email,
      user_name: user&.full_name,
      organization_id: organization&.id,
      organization_name: organization&.name,
      organization_subdomain: organization&.subdomain,
      roles: role_keys,
      capabilities: {
        can_manage_organization: can_manage_organization?,
        can_manage_appointments: can_manage_appointments?,
        can_book_appointments: can_book_appointments?
      }
    }
  end
  
  # Helper method for policies that need to check record ownership
  def owns_record?(record)
    return false unless user
    
    case record
    when User
      user == record
    when Post, Like
      user == record.user
    when Appointment
      user == record.client || user == record.professional
    else
      # For other models, check if they have a user association
      if record.respond_to?(:user)
        user == record.user
      elsif record.respond_to?(:user_id)
        user.id == record.user_id
      else
        false
      end
    end
  end
  
  # Helper method for policies that need to check organization membership
  def in_same_organization?(record)
    return false unless organization && record.respond_to?(:organization)
    organization == record.organization
  end
  
  # Helper method for checking if user can access a specific record
  def can_access_record?(record)
    return false unless user && organization
    
    # Must be in the same organization
    return false unless in_same_organization?(record)
    
    # Admin can access everything in their organization
    return true if admin?
    
    # Otherwise, check specific ownership or role-based access
    owns_record?(record) || role_based_access?(record)
  end
  
  private
  
  def role_based_access?(record)
    case record
    when Appointment
      # Professionals can access appointments they're assigned to
      # Secretaries can access all appointments in the organization
      professional? && record.professional == user ||
      secretary?
    else
      false
    end
  end
end