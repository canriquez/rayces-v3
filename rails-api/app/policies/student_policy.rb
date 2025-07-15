class StudentPolicy < ApplicationPolicy
  def index?
    true
  end
  
  def show?
    same_tenant? && (admin? || staff? || professional? || parent_of_student?)
  end
  
  def create?
    admin? || staff?
  end
  
  def update?
    admin? || staff? || (professional? && assigned_to_student?)
  end
  
  def destroy?
    admin?
  end
  
  private
  
  def parent_of_student?
    parent? && user.family_students.include?(record)
  end
  
  def assigned_to_student?
    professional? && record.assigned_professionals.include?(user)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      base_scope = scope.where(organization_id: user.organization_id)
      
      case
      when admin? || staff?
        base_scope
      when professional?
        base_scope.joins(:assigned_professionals).where(assigned_professionals: { user_id: user.id })
      when parent?
        base_scope.joins(:family_members).where(family_members: { user_id: user.id })
      else
        base_scope.none
      end
    end
  end
end