class LikesController < ApplicationController
  include Pundit::Authorization
  
  before_action :authenticate_google_user
  before_action :set_like, only: [:show, :destroy]
  after_action :verify_authorized
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def create
    @post = Post.find(params[:post_id])
    @like = @post.likes.new(user: current_user)
    authorize @like
    
    if @like.save
      render json: @like, status: :created
    else
      render json: { error: @like.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @like
    @like.destroy
    head :no_content
  end

  def show
    @post = Post.find(params[:post_id])
    @likes = @post.likes
    authorize @likes.first || Like.new(post: @post, user: current_user)

    render json: @likes
  end
  
  private
  
  def set_like
    @like = Like.find_by(post_id: params[:post_id], user_id: current_user.id)
    
    if @like.nil?
      render json: { error: "Like not found" }, status: :not_found
    end
  end
  
  def user_not_authorized
    render json: { error: 'You are not authorized to perform this action' }, 
           status: :forbidden
  end
end
