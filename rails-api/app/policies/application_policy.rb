# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user_context, :record, :user, :organization

  def initialize(user_context, record)
    @user_context = user_context
    @user = user_context.user
    @organization = user_context.organization
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user_context, :scope, :user, :organization

    def initialize(user_context, scope)
      @user_context = user_context
      @user = user_context.user
      @organization = user_context.organization
      @scope = scope
    end

    def resolve
      tenant_scope
    end

    private

    def tenant_scope
      # Always scope to organization for models that support multi-tenancy
      if scope.respond_to?(:where) && scope.column_names.include?('organization_id') && organization.present?
        scope.where(organization_id: organization.id)
      else
        scope
      end
    end
    
    def in_test_context?
      # Check if we're running tests (RSpec context) or test environment
      defined?(RSpec) || Rails.env.test? || ENV['RAILS_ENV'] == 'test'
    end
  end
  
  # Public helper methods for policies
  def same_tenant?
    # Always check tenant isolation properly, even in test context
    if record.respond_to?(:organization_id) && organization
      record.organization_id == organization.id
    else
      false
    end
  end
  
  def admin?
    user.admin?
  end
  
  def professional?
    user.professional?
  end
  
  def staff?
    user.staff?
  end
  
  def parent?
    user.guardian?
  end
  
  def owns_record?
    if record.respond_to?(:user_id)
      record.user_id == user.id
    elsif record.respond_to?(:id)
      record.id == user.id
    else
      false
    end
  end
  
  private
  
  def in_test_context?
    # Check if we're running tests (RSpec context) or test environment
    defined?(RSpec) || Rails.env.test? || ENV['RAILS_ENV'] == 'test'
  end
  
  def same_organization?
    same_tenant?
  end
  
  def owner?
    owns_record?
  end
end