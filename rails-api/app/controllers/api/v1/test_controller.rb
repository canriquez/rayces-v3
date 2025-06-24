class Api::V1::TestController < ApplicationController
  before_action :authenticate_google_user

  def index
    render json: { message: "Hello, #{current_user_email}!" }
  end

  private

  def authenticate_google_user
    render json: { error: 'Unauthorized request' }, status: :unauthorized unless current_user_id
  end

  def current_user_id
    request.env['google_user_id']
  end

  def current_user_email
    # Assuming you have a method to get the user's email from Google
    # This can be fetched from the token payload
    # You might want to implement this based on your needs
  end
end