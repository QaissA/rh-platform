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
    return render json: { error: "Accès refusé" }, status: :forbidden unless can_decide?(@request)
    return render json: { error: "Demande déjà traitée" }, status: :unprocessable_content unless @request.awaiting?

    if @request.pending?
      @request.update!(status: "pending_hr", decided_by: current_user_id, decided_at: Time.current)
      notify_leave("leave_manager_approved",
                   "Votre manager a accepté votre congé",
                   "Votre demande est transmise à la RH pour confirmation.")
      return render json: request_json(@request)
    end

    ActiveRecord::Base.transaction do
      balance = LeaveBalance.find_or_create_by!(user_id: @request.user_id)
      balance.update!(days_remaining: balance.days_remaining - @request.working_days)
      @request.update!(status: "approved", decided_by: current_user_id, decided_at: Time.current)
    end

    notify_leave("leave_hr_approved",
                 "Votre congé est confirmé",
                 "La RH a validé votre demande. Le solde a été débité.")
    render json: request_json(@request)
  rescue ActiveRecord::RecordInvalid
    render json: { error: "Solde insuffisant" }, status: :unprocessable_content
  end

  # PATCH /requests/:id/reject  -> manager (pending) or HR (pending_hr) refuses.
  def reject
    return render json: { error: "Accès refusé" }, status: :forbidden unless can_decide?(@request)
    return render json: { error: "Demande déjà traitée" }, status: :unprocessable_content unless @request.awaiting?

    @request.update!(
      status: "rejected",
      decided_by: current_user_id,
      decided_at: Time.current,
      decision_comment: params[:comment],
    )

    render json: request_json(@request)
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

  # Step 1 (pending): manager of the team, or admin.
  # Step 2 (pending_hr): RH, or admin. Manager cannot skip HR.
  def can_decide?(req)
    if req.pending?
      admin? || (manager? && managed_team_ids.include?(req.team_id))
    elsif req.pending_hr?
      admin? || rh?
    else
      false
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

  def notify_leave(kind, title, body)
    NotificationClient.notify(
      user_id: @request.user_id,
      kind: kind,
      title: title,
      body: body,
      link: "/conges",
    )
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
