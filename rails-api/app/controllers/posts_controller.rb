class PostsController < ApplicationController
  before_action :set_post, only: [:show, :update, :destroy]

  # GET /posts
=begin 
  def index
    render json: all_posts.map { |post| post.as_json.merge(metadata: parse_metadata(post)) }
  end
=end

  def index
    user_id = current_user.id
    all_posts_with_likes = Post.includes(:likes).all

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
    render json: @post
  end

  # POST /posts
  def create
    @post = Post.new(post_params)

    if @post.save
      render json: @post, status: :created, location: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/:id
  def update
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:id
  def destroy
    @post.destroy
  end

  private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:post_id, :hash_id, :source, :metadata, :filename)
    end

    def all_posts
      @all_posts ||= Post.all
    end

    def parse_metadata(post)
      JSON.parse(post.metadata)
    rescue JSON::ParserError
      {}
    end
end
