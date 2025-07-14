# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]
  
  def index
    @users = policy_scope(User)
    render_paginated(@users, UserSerializer)
  end
  
  def show
    authorize @user
    render json: @user, serializer: UserSerializer
  end
  
  def create
    @user = User.new(user_params)
    @user.organization = current_user.organization
    
    authorize @user
    
    if @user.save
      render json: @user, serializer: UserSerializer, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def update
    authorize @user
    
    if @user.update(user_params)
      render json: @user, serializer: UserSerializer
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @user
    @user.destroy
    head :no_content
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    permitted = [:email, :first_name, :last_name, :phone, :password]
    permitted << :role if policy(@user || User).manage_role?
    
    params.require(:user).permit(permitted)
  end
end