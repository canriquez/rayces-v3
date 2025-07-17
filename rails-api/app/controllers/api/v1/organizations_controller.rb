# app/controllers/api/v1/organizations_controller.rb
module Api
  module V1
    class OrganizationsController < BaseController
      
      def show
        @organization = current_user.organization
        render json: { organization: ActiveModelSerializers::SerializableResource.new(
          @organization,
          serializer: OrganizationSerializer,
          scope: current_user
        ).as_json }
      end
      
      def update
        authorize ActsAsTenant.current_tenant || current_user.organization
        
        @organization = ActsAsTenant.current_tenant || current_user.organization
        
        if @organization.update(organization_params)
          render json: { organization: ActiveModelSerializers::SerializableResource.new(
            @organization,
            serializer: OrganizationSerializer,
            scope: current_user
          ).as_json }
        else
          render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      private
      
      def organization_params
        params.require(:organization).permit(:name, :phone, :email, :address, settings: {})
      end
    end
  end
end