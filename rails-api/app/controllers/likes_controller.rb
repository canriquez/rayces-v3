class LikesController < ApplicationController
  before_action :authenticate_google_user

  def create
    @post = Post.find(params[:post_id])
    @like = @post.likes.new(user: current_user)

    if @like.save
      render json: @like, status: :created
    else
      render json: { error: @like.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @like = Like.find_by(post_id: params[:post_id], user_id: current_user.id)

    if @like
      @like.destroy
      render json: { message: "Like removed" }, status: :ok
    else
      render json: { error: "Like not found" }, status: :not_found
    end
  end

  def show
    @post = Post.find(params[:post_id])
    @likes = @post.likes

    render json: @likes
  end
end
