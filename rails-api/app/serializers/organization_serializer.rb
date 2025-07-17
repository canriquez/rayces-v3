# app/serializers/organization_serializer.rb
class OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :subdomain, :phone, :address,
             :active, :created_at, :updated_at
  
  attribute :email, if: :can_view_email?
  attribute :settings, if: :can_view_settings?
  
  def can_view_email?
    # Only admins and staff can see organization email
    current_user&.admin? || current_user&.staff?
  end
  
  def can_view_settings?
    # Only admins can see organization settings
    current_user&.admin?
  end
  
  private
  
  def current_user
    instance_options[:current_user] || scope
  end
end