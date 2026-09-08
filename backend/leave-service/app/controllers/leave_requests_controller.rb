class LeaveRequestsController < ApplicationController
  before_action :require_user!
  before_action :set_request, only: [:approve, :reject]

  # GET /requests  -> current user's leave requests (optional ?status= filter)
  def index
    requests = LeaveRequest.where(user_id: current_user_id).order(created_at: :desc)
    requests = filter_status(requests)
    render json: requests.map { |r| request_json(r) }
  end

  # GET /requests/team  -> requests in the caller's validation scope.
  # Managers see their teams; RH and admins see every request.
  def team
    return render json: { error: "Accès réservé aux responsables" }, status: :forbidden unless can_review_team?

    requests = company_wide_reviewer? ? LeaveRequest.all : LeaveRequest.for_teams(managed_team_ids)
    requests = filter_status(requests)
    render json: requests.order(created_at: :desc).map { |r| request_json(r) }
  end

  # POST /requests  -> submit a new leave request
  def create
    leave_request = LeaveRequest.new(leave_request_params)
    leave_request.user_id = current_user_id
    leave_request.team_id = current_user_team_id

    if leave_request.save
      render json: request_json(leave_request), status: :created
    else
      render json: { errors: leave_request.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH /requests/:id/approve
  # Manager (step 1) moves pending -> pending_hr. HR (step 2) confirms and debits.
  def approve
    render_decision(Leave::Decide.new(request: @request, actor: decide_actor).approve)
  end

  # PATCH /requests/:id/reject  -> manager (pending) or HR (pending_hr) refuses.
  def reject
    render_decision(Leave::Decide.new(request: @request, actor: decide_actor).reject(comment: params[:comment]))
  end

  private

  def set_request
    @request = LeaveRequest.find_by(id: params[:id])
    render json: { error: "Demande introuvable" }, status: :not_found unless @request
  end

  def can_review_team?
    manager? || rh? || admin?
  end

  def company_wide_reviewer?
    rh? || admin?
  end

  def decide_actor
    Leave::Decide::Actor.new(
      id: current_user_id.to_i,
      role: current_user_role,
      managed_team_ids: managed_team_ids,
    )
  end

  def render_decision(result)
    if result.ok
      render json: request_json(@request)
    else
      render json: { error: result.error }, status: result.status
    end
  end

  def filter_status(requests)
    return requests if params[:status].blank?

    statuses = params[:status].to_s.split(",").map(&:strip).reject(&:blank?)
    requests.where(status: statuses)
  end

  def leave_request_params
    params.permit(:start_date, :end_date, :reason)
  end

  def request_json(r)
    {
      id: r.id, user_id: r.user_id, team_id: r.team_id,
      start_date: r.start_date, end_date: r.end_date,
      status: r.status, reason: r.reason, days: r.working_days,
      decided_by: r.decided_by, decided_at: r.decided_at, decision_comment: r.decision_comment
    }
  end
end
