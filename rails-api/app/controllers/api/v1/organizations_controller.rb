# app/controllers/api/v1/organizations_controller.rb
class Api::V1::OrganizationsController < Api::V1::BaseController
  before_action :set_organization, only: [:show, :update]
  
  def show
    authorize @organization
    render json: @organization, serializer: OrganizationSerializer
  end
  
  def update
    authorize @organization
    
    if @organization.update(organization_params)
      render json: @organization, serializer: OrganizationSerializer
    else
      render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_organization
    @organization = current_user&.organization
  end
  
  def organization_params
    params.require(:organization).permit(:name, :phone, :email, :address, settings: {})
  end
end