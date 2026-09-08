class PresencesController < ApplicationController
  before_action :require_user!

  MAX_RANGE_DAYS = 92

  # POST /presences  { start_date, end_date, status }
  # The caller declares their own work location (on_site|remote) for every day in
  # the range. Existing declarations for those days are overwritten (upsert).
  def create
    status = params[:status].to_s
    unless Presence::STATUSES.include?(status)
      return render json: { error: "Statut invalide" }, status: :unprocessable_content
    end

    start_date = parse_date(params[:start_date])
    end_date   = parse_date(params[:end_date]) || start_date
    if start_date.nil? || end_date < start_date
      return render json: { error: "Dates invalides" }, status: :unprocessable_content
    end
    if (end_date - start_date).to_i > MAX_RANGE_DAYS
      return render json: { error: "Plage trop large" }, status: :unprocessable_content
    end

    entries = []
    ActiveRecord::Base.transaction do
      (start_date..end_date).each do |day|
        presence = Presence.find_or_initialize_by(user_id: current_user_id, date: day)
        presence.team_id = current_user_team_id
        presence.status = status
        presence.save!
        entries << presence_json(presence)
      end
    end

    render json: { entries: entries }, status: :created
  end

  private

  def presence_json(p)
    { user_id: p.user_id, date: p.date.iso8601, status: p.status }
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end
end
