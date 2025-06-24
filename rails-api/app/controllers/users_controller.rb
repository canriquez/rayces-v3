class UsersController < ApplicationController

  def sign_in
    user_info = @google_user
    user = find_or_create_user(user_info)

    if user.new_record?
      new_user = true
      user.save!
    else
      new_user = false
    end

    render json: { user: user, new_user: new_user }
  end
end
