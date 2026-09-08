# Demo data for the leave-service. Run with: bin/rails db:seed
# Ids mirror auth-service seed order: admin=1, manager(Mona)=2, Emma Employee=3.
# Emma is on the Atlas team (id 3), whose BU manager is Mona.
EMMA = 3
ATLAS_TEAM = 3

LeaveBalance.find_or_create_by!(user_id: EMMA) do |b|
  b.days_remaining = 18.5
end

[
  { start_date: "2026-08-01", end_date: "2026-08-05", status: "pending",    reason: "Congés payés" },
  { start_date: "2026-09-10", end_date: "2026-09-11", status: "pending_hr", reason: "RTT" },
  { start_date: "2026-07-14", end_date: "2026-07-14", status: "approved",   reason: "RTT" },
  { start_date: "2026-06-02", end_date: "2026-06-03", status: "approved",   reason: "Congés payés" },
  { start_date: "2026-05-21", end_date: "2026-05-21", status: "rejected",   reason: "Sans solde" },
].each do |r|
  lr = LeaveRequest.find_or_create_by!(user_id: EMMA, start_date: r[:start_date], end_date: r[:end_date]) do |row|
    row.status = r[:status]
    row.reason = r[:reason]
    row.team_id = ATLAS_TEAM
  end
  lr.update!(status: r[:status], reason: r[:reason], team_id: ATLAS_TEAM)
end

puts "Seeded leave balance + #{LeaveRequest.count} request(s)."

# --- Team schedule ("emploi du temps") demo data -----------------------------
# The team calendar is scoped by the caller's *current* team, which in
# auth-service is the Atlas team (id 3): Emma (3) and Youssef (4). We seed
# approved leaves (=> holiday) and presence declarations (on_site/remote) there
# so the calendar shows all three states for August 2026 (today = 2026-08-03).
YOUSSEF = 4

LeaveBalance.find_or_create_by!(user_id: YOUSSEF) { |b| b.days_remaining = 21.0 }

[
  { user_id: EMMA,    start_date: "2026-08-20", end_date: "2026-08-21", reason: "Congés payés" },
  { user_id: YOUSSEF, start_date: "2026-08-12", end_date: "2026-08-14", reason: "RTT" },
].each do |r|
  LeaveRequest.find_or_create_by!(user_id: r[:user_id], start_date: r[:start_date], end_date: r[:end_date]) do |lr|
    lr.status = "approved"
    lr.reason = r[:reason]
    lr.team_id = ATLAS_TEAM
  end
end

# Remote-work declarations (days not listed default to on-site).
presences = {
  EMMA    => %w[2026-08-04 2026-08-05 2026-08-11 2026-08-18 2026-08-25],
  YOUSSEF => %w[2026-08-03 2026-08-06 2026-08-07 2026-08-19 2026-08-26 2026-08-27],
}
presences.each do |user_id, dates|
  dates.each do |d|
    Presence.find_or_create_by!(user_id: user_id, date: d) do |p|
      p.team_id = ATLAS_TEAM
      p.status = "remote"
    end
  end
end

puts "Seeded #{Presence.count} presence declaration(s)."
