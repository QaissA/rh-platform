class ScheduleController < ApplicationController
  before_action :require_user!

  # Default window when the caller doesn't pass ?start=&end= : the current month.
  MAX_RANGE_DAYS = 92

  # GET /schedule?start=YYYY-MM-DD&end=YYYY-MM-DD
  # Team "emploi du temps": the daily state of every member of the caller's team
  # over the window. State is one of on_site | remote | holiday, where holiday is
  # derived from approved leave requests and takes precedence over any presence.
  def index
    team_id = current_user_team_id
    range_start, range_end = window
    return render json: { start: range_start, end: range_end, entries: [] } if team_id.blank?

    states = {} # [user_id, date_string] => "on_site" | "remote" | "holiday"

    Presence.for_team(team_id).in_range(range_start, range_end).each do |p|
      states[[p.user_id, p.date.iso8601]] = p.status
    end

    # Approved leaves win over any presence on the same day.
    LeaveRequest.for_teams([team_id]).where(status: "approved")
                .overlapping(range_start, range_end).each do |leave|
      day = [leave.start_date, range_start].max
      last = [leave.end_date, range_end].min
      while day <= last
        states[[leave.user_id, day.iso8601]] = "holiday"
        day += 1
      end
    end

    entries = states.map { |(user_id, date), status| { user_id: user_id, date: date, status: status } }
                    .sort_by { |e| [e[:date], e[:user_id]] }

    render json: { start: range_start.iso8601, end: range_end.iso8601, entries: entries }
  end

  private

  # Clamped [start, end] window, defaulting to the current calendar month and
  # capped at MAX_RANGE_DAYS so a wide query can't scan the whole table.
  def window
    start_date = parse_date(params[:start]) || Date.current.beginning_of_month
    end_date   = parse_date(params[:end])   || start_date.end_of_month
    end_date = start_date if end_date < start_date
    end_date = [end_date, start_date + MAX_RANGE_DAYS].min
    [start_date, end_date]
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end
end
