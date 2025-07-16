# app/controllers/api/v1/organization_controller.rb
class Api::V1::OrganizationController < Api::V1::BaseController
  def show
    # Return the current user's organization
    authorize current_user.organization, :show?
    render json: current_user.organization, serializer: OrganizationSerializer
  end
  
  def update
    authorize current_user.organization
    
    if current_user.organization.update(organization_params)
      render json: current_user.organization, serializer: OrganizationSerializer
    else
      render json: { errors: current_user.organization.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def organization_params
    params.require(:organization).permit(:name, :subdomain, settings: {})
  end
end