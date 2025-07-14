# app/serializers/organization_serializer.rb
class OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :subdomain, :phone, :email, :address,
             :active, :created_at, :updated_at
  
  attributes :settings, if: :can_view_settings?
  
  def can_view_settings?
    # Only admins can see organization settings
    current_user&.admin?
  end
  
  private
  
  def current_user
    instance_options[:current_user] || scope
  end
end