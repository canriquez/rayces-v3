class ApplicationController < ActionController::API
  before_action :authenticate_google_user

  private

  def authenticate_google_user
    @google_user = request.env['google_user']
    unless @google_user
      render json: { error: 'Unauthorized access attempt. Sorry.' }, status: :unauthorized
    else
      @current_user = find_or_create_user(@google_user)
      unless @current_user
        render json: { error: 'User could not be authenticated. Please try again.' }, status: :unauthorized
      end
    end
  end

  def current_user
    @current_user
  end

  def find_or_create_user(google_user)
    user = User.find_or_initialize_by(uid: google_user['sub'])

    if user.new_record?
      user.name = google_user['name']
      user.email = google_user['email']
      user.image = google_user['picture']
      user.username = google_user['email'].split('@').first
      user.save!
    end

    user
  end
end
