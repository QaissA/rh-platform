class LeaveBalancesController < ApplicationController
  before_action :require_user!

  # GET /balance  -> current user's remaining leave (solde de congés)
  def show
    balance = LeaveBalance.find_or_initialize_by(user_id: current_user_id)
    render json: { user_id: balance.user_id.to_i, days_remaining: balance.days_remaining || 0 }
  end
end
