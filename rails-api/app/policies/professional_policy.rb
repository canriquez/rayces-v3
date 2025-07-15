class ProfessionalPolicy < ApplicationPolicy
  def index?
    true # All can view professionals in their organization
  end
  
  def show?
    same_tenant?
  end
  
  def create?
    admin? || staff?
  end
  
  def update?
    owns_record? || admin? || staff?
  end
  
  def destroy?
    admin?
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end