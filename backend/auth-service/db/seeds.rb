# Demo data for the skeleton. Run with: bin/rails db:seed
platform   = Team.find_or_create_by!(name: "Platform")
people_ops = Team.find_or_create_by!(name: "People Ops")

people = [
  { email: "admin@rh.local",    first: "Adam",    last: "Admin",    role: "admin",    pwd: "password", team: platform },
  { email: "manager@rh.local",  first: "Mona",    last: "Manager",  role: "manager",  pwd: "password", team: platform },
  { email: "employee@rh.local", first: "Emma",    last: "Employee", role: "employee", pwd: "password", team: platform },
  { email: "youssef@rh.local",  first: "Youssef", last: "Benali",   role: "employee", team: platform },
  { email: "clara@rh.local",    first: "Clara",   last: "Meunier",  role: "employee", team: platform },
  { email: "karim@rh.local",    first: "Karim",   last: "Haddad",   role: "manager",  team: people_ops },
  { email: "thomas@rh.local",   first: "Thomas",  last: "Roy",      role: "employee", team: people_ops },
  { email: "aicha@rh.local",    first: "Aïcha",   last: "Diallo",   role: "employee", team: people_ops },
  { email: "lucas@rh.local",    first: "Lucas",   last: "Girard",   role: "employee", team: people_ops },
  { email: "rh@rh.local",       first: "Rania",   last: "Ressource", role: "rh",      pwd: "password", team: platform },
]

people.each do |p|
  User.find_or_create_by!(email: p[:email]) do |u|
    u.password = p[:pwd] || "password"
    u.first_name = p[:first]
    u.last_name = p[:last]
    u.role = p[:role]
    u.team = p[:team]
  end
end

find = ->(email) { User.find_by!(email: email) }

# --- Org structure -----------------------------------------------------------
# Ensure roles are current for demo accounts (find_or_create only sets on create).
find.("rh@rh.local").update!(role: "rh")
%w[youssef@rh.local clara@rh.local aicha@rh.local].each { |e| find.(e).update!(role: "lead") }

engineering = BusinessUnit.find_or_create_by!(name: "Engineering")
peopleops   = BusinessUnit.find_or_create_by!(name: "People Ops")

atlas       = Project.find_or_create_by!(name: "Atlas",       business_unit: engineering)
nimbus      = Project.find_or_create_by!(name: "Nimbus",      business_unit: engineering)
recrutement = Project.find_or_create_by!(name: "Recrutement", business_unit: peopleops)

# Designate managers (BU) and leads (project). Roles above must be set first.
engineering.update!(manager: find.("manager@rh.local"))
peopleops.update!(manager: find.("karim@rh.local"))
atlas.update!(lead: find.("youssef@rh.local"))
nimbus.update!(lead: find.("clara@rh.local"))
recrutement.update!(lead: find.("aicha@rh.local"))

# Each project has one team (its roster).
atlas_team  = Team.find_or_create_by!(name: "Atlas")       { |t| t.project = atlas }
nimbus_team = Team.find_or_create_by!(name: "Nimbus")      { |t| t.project = nimbus }
recrut_team = Team.find_or_create_by!(name: "Recrutement") { |t| t.project = recrutement }
atlas_team.update!(project: atlas)
nimbus_team.update!(project: nimbus)
recrut_team.update!(project: recrutement)

# Affect people. Employees/leads join a team (project + BU are derived);
# managers are affected to a BU directly (no team).
find.("manager@rh.local").update!(team: nil, business_unit: engineering)
find.("karim@rh.local").update!(team: nil, business_unit: peopleops)
find.("youssef@rh.local").update!(team: atlas_team)
find.("clara@rh.local").update!(team: nimbus_team)
find.("aicha@rh.local").update!(team: recrut_team)
find.("employee@rh.local").update!(
  team: atlas_team,
  job_title: "Développeuse",
  address_line: "12 rue des Lilas",
  postal_code: "75011",
  city: "Paris",
  country: "FR",
  salary_cents: 3_200_00,
  contract_type: "cdi",
  hired_on: Date.new(2024, 3, 1),
  iban: "FR7630006000011234567890189",
)
find.("youssef@rh.local").update!(team: atlas_team, pending_job_title: "Lead développeur")
find.("lucas@rh.local").update!(team: nimbus_team)
find.("thomas@rh.local").update!(team: recrut_team)

emma = find.("employee@rh.local")
[
  { kind: "document_ready", title: "Votre document est prêt", body: "La RH a mis votre document administratif à disposition.", link: "/documents" },
  { kind: "leave_hr_approved", title: "Votre congé est confirmé", body: "La RH a validé votre demande.", link: "/conges" },
].each do |n|
  Notification.find_or_create_by!(user: emma, kind: n[:kind], title: n[:title]) do |row|
    row.body = n[:body]
    row.link = n[:link]
  end
end

puts "Seeded #{BusinessUnit.count} BU(s), #{Project.count} project(s), #{Team.count} team(s), #{User.count} user(s), #{Notification.count} notification(s)."
