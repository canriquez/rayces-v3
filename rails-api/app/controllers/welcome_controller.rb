class WelcomeController < ApplicationController
  def index
    render json: { message: "Hello, World! This is Working." }
  end
end
