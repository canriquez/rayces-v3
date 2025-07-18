class PostsController < ApplicationController
  include Pundit::Authorization
  
  before_action :set_post, only: [:show, :update, :destroy]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # GET /posts
=begin 
  def index
    render json: all_posts.map { |post| post.as_json.merge(metadata: parse_metadata(post)) }
  end
=end

  def index
    @posts = policy_scope(Post)
    user_id = current_user.id
    all_posts_with_likes = @posts.includes(:likes)

    likes_for_user = Like.where(user_id: user_id).pluck(:post_id).to_set
    
    posts_to_ui =  all_posts_with_likes.map do |post|
    metadata = parse_metadata(post)
    creation_date = Date.parse(metadata["creation_date"]) rescue Date.new(1970, 1, 1)

      {
        id: post.id,
        post_id: post.post_id,
        hash_id: post.hash_id,
        source: post.source,
        metadata: parse_metadata(post),
        filename: post.filename,
        created_at: post.created_at,
        updated_at: post.updated_at,
        likes_count: post.likes.size,
        liked_by_current_user: likes_for_user.include?(post.id),
        creation_date: creation_date
      }
    end

    # Sort by creation_date in descending order
    sorted_posts = posts_to_ui.sort_by { |post| post[:creation_date] }.reverse

    #render json: posts_to_ui.as_json;
    render json: sorted_posts.as_json
  end


  # GET /posts/:id
  def show
    authorize @post
    render json: @post
  end

  # POST /posts
  def create
    @post = Post.new(post_params)
    @post.user = current_user
    authorize @post
    
    if @post.save
      render json: @post, status: :created, location: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/:id
  def update
    authorize @post
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:id
  def destroy
    authorize @post
    @post.destroy
    head :no_content
  end

  private

    def set_post
      # Bypass tenant scoping for authorization to work properly
      # This allows Pundit policies to handle cross-tenant access denials (403)
      # instead of getting RecordNotFound (404) from scoped queries
      @post = ActsAsTenant.without_tenant { Post.find(params[:id]) }
    end

    def post_params
      params.require(:post).permit(:post_id, :hash_id, :source, :metadata, :filename, :content)
    end

    def all_posts
      @all_posts ||= Post.all
    end

    def parse_metadata(post)
      JSON.parse(post.metadata)
    rescue JSON::ParserError
      {}
    end
    
    def user_not_authorized
      render json: { error: 'You are not authorized to perform this action' }, 
             status: :forbidden
    end
end
