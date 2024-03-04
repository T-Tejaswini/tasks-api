class Api::UsersController < ApplicationController
  # GET /api/users/{userId}/tasks
  def tasks
    user = User.find(params[:id])

    render json: user.tasks
  end
end
