# Role-Based Permission Matrix Implementation
# Defines the complete permission system for multi-tenant SaaS

# Permission matrix configuration
ROLE_PERMISSIONS = {
  admin: {
    organizations: [:index, :show, :create, :update, :destroy],
    users: [:index, :show, :create, :update, :destroy],
    appointments: [:index, :show, :create, :update, :destroy, :pre_confirm, :confirm, :execute, :cancel],
    professionals: [:index, :show, :create, :update, :destroy],
    students: [:index, :show, :create, :update, :destroy],
    reports: [:index, :show, :create, :update, :destroy],
    settings: [:index, :show, :update],
    billing: [:index, :show, :create, :update]
  },
  
  professional: {
    organizations: [:show],
    users: [:index, :show, :update_own],
    appointments: [:index, :show, :update_assigned, :execute_assigned, :cancel_assigned],
    professionals: [:show_own, :update_own],
    students: [:index, :show, :update_assigned],
    reports: [:create_own, :show_own, :update_own],
    settings: [:show]
  },
  
  secretary: {
    organizations: [:show],
    users: [:index, :show, :create, :update_clients],
    appointments: [:index, :show, :create, :update, :pre_confirm, :confirm, :cancel],
    professionals: [:index, :show],
    students: [:index, :show, :create, :update],
    reports: [:index, :show],
    settings: [:show],
    billing: [:index, :show, :create]
  },
  
  client: {
    organizations: [:show],
    users: [:show_own, :update_own],
    appointments: [:index_own, :show_own, :create_own, :update_own, :cancel_own],
    professionals: [:index, :show],
    students: [:index_family, :show_family, :create_family, :update_family],
    reports: [:show_own]
  }
}.freeze

# Base class for permission checking
class PermissionMatrix
  def self.can?(user, action, resource_type)
    return false unless user&.roles&.any?
    
    # Get user's highest role
    user_role = user.highest_role
    
    # Check if role has permission for this action and resource
    role_permissions = ROLE_PERMISSIONS[user_role.to_sym]
    return false unless role_permissions
    
    resource_permissions = role_permissions[resource_type.to_sym]
    return false unless resource_permissions
    
    resource_permissions.include?(action.to_sym)
  end
  
  def self.permissions_for(user, resource_type)
    return [] unless user&.roles&.any?
    
    user_role = user.highest_role
    role_permissions = ROLE_PERMISSIONS[user_role.to_sym]
    
    role_permissions&.dig(resource_type.to_sym) || []
  end
end

# Enhanced policies using the permission matrix
class OrganizationPolicy < ApplicationPolicy
  def index?
    PermissionMatrix.can?(user, :index, :organizations)
  end
  
  def show?
    return false unless same_organization?
    PermissionMatrix.can?(user, :show, :organizations)
  end
  
  def create?
    PermissionMatrix.can?(user, :create, :organizations)
  end
  
  def update?
    return false unless same_organization?
    PermissionMatrix.can?(user, :update, :organizations)
  end
  
  def destroy?
    return false unless same_organization?
    PermissionMatrix.can?(user, :destroy, :organizations)
  end
end

class UserPolicy < ApplicationPolicy
  def index?
    PermissionMatrix.can?(user, :index, :users)
  end
  
  def show?
    return false unless same_organization?
    return true if own_record?
    PermissionMatrix.can?(user, :show, :users)
  end
  
  def create?
    return false unless same_organization?
    PermissionMatrix.can?(user, :create, :users)
  end
  
  def update?
    return false unless same_organization?
    return true if own_record? && PermissionMatrix.can?(user, :update_own, :users)
    return true if can_update_clients?
    PermissionMatrix.can?(user, :update, :users)
  end
  
  def destroy?
    return false unless same_organization?
    return false if own_record? # Can't delete self
    PermissionMatrix.can?(user, :destroy, :users)
  end
  
  private
  
  def own_record?
    user.id == record.id
  end
  
  def can_update_clients?
    record.enhanced_client? && PermissionMatrix.can?(user, :update_clients, :users)
  end
end

class AppointmentPolicy < ApplicationPolicy
  def index?
    return index_own? if user.enhanced_client?
    PermissionMatrix.can?(user, :index, :appointments)
  end
  
  def show?
    return false unless same_organization?
    return true if own_appointment?
    return true if assigned_professional?
    return true if family_appointment?
    PermissionMatrix.can?(user, :show, :appointments)
  end
  
  def create?
    return false unless same_organization?
    return true if PermissionMatrix.can?(user, :create_own, :appointments)
    PermissionMatrix.can?(user, :create, :appointments)
  end
  
  def update?
    return false unless same_organization?
    return false unless appointment_state_allows_update?
    return true if own_appointment? && PermissionMatrix.can?(user, :update_own, :appointments)
    return true if assigned_professional? && PermissionMatrix.can?(user, :update_assigned, :appointments)
    PermissionMatrix.can?(user, :update, :appointments)
  end
  
  def pre_confirm?
    return false unless same_organization?
    return false unless record.draft?
    PermissionMatrix.can?(user, :pre_confirm, :appointments)
  end
  
  def confirm?
    return false unless same_organization?
    return false unless record.pre_confirmed?
    PermissionMatrix.can?(user, :confirm, :appointments)
  end
  
  def execute?
    return false unless same_organization?
    return false unless record.confirmed?
    return true if assigned_professional? && PermissionMatrix.can?(user, :execute_assigned, :appointments)
    PermissionMatrix.can?(user, :execute, :appointments)
  end
  
  def cancel?
    return false unless same_organization?
    return false if record.executed? || record.cancelled?
    return true if own_appointment? && record.cancellable_by_client? && PermissionMatrix.can?(user, :cancel_own, :appointments)
    return true if assigned_professional? && PermissionMatrix.can?(user, :cancel_assigned, :appointments)
    PermissionMatrix.can?(user, :cancel, :appointments)
  end
  
  private
  
  def index_own?
    PermissionMatrix.can?(user, :index_own, :appointments)
  end
  
  def own_appointment?
    record.client_id == user.id
  end
  
  def assigned_professional?
    user.enhanced_professional? && record.professional_id == user.professional_profile&.id
  end
  
  def family_appointment?
    user.enhanced_client? && user.family_member_ids.include?(record.student_id)
  end
  
  def appointment_state_allows_update?
    case record.state
    when 'draft'
      true
    when 'pre_confirmed'
      user.enhanced_admin? || user.enhanced_secretary?
    when 'confirmed'
      user.enhanced_admin? || user.enhanced_secretary? || assigned_professional?
    when 'executed'
      user.enhanced_admin? # Only admins can modify executed appointments
    when 'cancelled'
      false # No one can modify cancelled appointments
    else
      false
    end
  end
  
  class Scope < Scope
    def resolve
      # Apply organization scoping first
      base_scope = scope.where(organization_id: user.organization_id)
      
      case user.highest_role
      when 'admin', 'secretary'
        # Full access to all appointments in organization
        base_scope
      when 'professional'
        # Only assigned appointments
        base_scope.where(professional_id: user.professional_profile&.id)
      when 'client'
        # Own and family appointments
        student_ids = [user.id] + user.family_member_ids
        base_scope.where(student_id: student_ids)
      else
        base_scope.none
      end
    end
  end
end

# Permission helper for views and controllers
module PermissionHelper
  def can?(action, resource)
    return false unless current_user
    
    case resource
    when Class
      PermissionMatrix.can?(current_user, action, resource.name.underscore.pluralize)
    when String, Symbol
      PermissionMatrix.can?(current_user, action, resource)
    else
      policy = policy(resource)
      policy.respond_to?("#{action}?") && policy.public_send("#{action}?")
    end
  end
  
  def cannot?(action, resource)
    !can?(action, resource)
  end
  
  def user_permissions(resource_type)
    PermissionMatrix.permissions_for(current_user, resource_type)
  end
end

# Enhanced User model with role hierarchy
class User < ApplicationRecord
  acts_as_tenant :organization
  
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  
  # Role hierarchy (higher index = higher permission level)
  ROLE_HIERARCHY = %w[client professional secretary admin].freeze
  
  def highest_role
    return nil unless roles.any?
    
    user_role_names = roles.pluck(:name)
    ROLE_HIERARCHY.reverse.find { |role| user_role_names.include?(role) }
  end
  
  def role_level
    ROLE_HIERARCHY.index(highest_role) || -1
  end
  
  def has_role?(role_name)
    roles.exists?(name: role_name)
  end
  
  def enhanced_admin?
    has_role?('admin')
  end
  
  def enhanced_professional?
    has_role?('professional')
  end
  
  def enhanced_secretary?
    has_role?('secretary')
  end
  
  def enhanced_client?
    has_role?('client')
  end
  
  def can_access_resource?(resource_type, action)
    PermissionMatrix.can?(self, action, resource_type)
  end
  
  def family_member_ids
    # Implementation depends on your family relationship model
    # This is a placeholder
    []
  end
end

# Role model with permission caching
class Role < ApplicationRecord
  acts_as_tenant :organization
  
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization_id }
  
  # Create default roles for an organization
  def self.create_defaults_for_organization(organization)
    default_roles = [
      { name: 'admin', description: 'Full access to organization' },
      { name: 'secretary', description: 'Administrative and booking management' },
      { name: 'professional', description: 'Professional service provider' },
      { name: 'client', description: 'Client user with limited access' }
    ]
    
    default_roles.each do |role_data|
      find_or_create_by(name: role_data[:name], organization: organization) do |role|
        role.description = role_data[:description]
      end
    end
  end
  
  def permissions_for(resource_type)
    PermissionMatrix.permissions_for(
      OpenStruct.new(highest_role: name, roles: [self]),
      resource_type
    )
  end
end

# Controller mixin for permission checking
module PermissionController
  extend ActiveSupport::Concern
  
  included do
    before_action :check_resource_permission, except: [:index, :show]
    helper_method :can?, :cannot?, :user_permissions if respond_to?(:helper_method)
  end
  
  private
  
  def check_resource_permission
    resource_type = controller_name
    action = action_name.to_sym
    
    # Map controller actions to permission actions
    permission_action = case action
    when :new, :create
      :create
    when :edit, :update
      :update
    when :destroy
      :destroy
    else
      action
    end
    
    unless PermissionMatrix.can?(current_user, permission_action, resource_type)
      render json: { 
        error: 'Insufficient permissions',
        code: 'INSUFFICIENT_PERMISSIONS'
      }, status: :forbidden
    end
  end
end