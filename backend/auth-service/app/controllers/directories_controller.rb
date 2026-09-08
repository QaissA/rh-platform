class DirectoriesController < ApplicationController
  before_action :require_authentication!

  def index
    users = User.where.not(id: current_user.id).order(:last_name, :first_name, :id)
    render json: users.map { |u| member_json(u) }
  end
end
