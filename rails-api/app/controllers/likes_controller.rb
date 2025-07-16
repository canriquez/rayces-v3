class LikesController < Api::V1::BaseController
  before_action :set_post
  before_action :set_like, only: [:show, :destroy]

  def create
    # Create like within tenant context
    @like = @post.likes.new(user: current_user, organization: ActsAsTenant.current_tenant)
    authorize @like
    
    if @like.save
      render json: @like, serializer: LikeSerializer, status: :created
    else
      render json: { error: @like.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    # If no like found, return 404
    unless @like
      render json: { error: "Like not found" }, status: :not_found
      return
    end
    
    authorize @like
    @like.destroy
    head :no_content
  end

  def show
    # Return the current user's like for this post, or null if they haven't liked it
    authorize @like || Like.new(post: @post, user: current_user)
    
    if @like
      render json: @like, serializer: LikeSerializer
    else
      render json: { like: nil }
    end
  end
  
  private
  
  def set_post
    # Bypass tenant scoping for authorization to work properly (same pattern as PostsController)
    @post = ActsAsTenant.without_tenant { Post.find(params[:post_id]) }
  end
  
  def set_like
    # Find the current user's like for this post within tenant context
    @like = Like.find_by(post_id: params[:post_id], user_id: current_user.id)
  end
  
end
