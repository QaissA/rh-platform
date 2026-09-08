class TeamsController < ApplicationController
  before_action :require_authentication!, only: [:mine]
  before_action :require_admin!, only: [:index, :show, :create, :update, :destroy]
  before_action :set_team, only: [:show, :update, :destroy]

  # GET /teams  -> all teams with member counts (admin only)
  def index
    teams = Team.order(:name)
    render json: teams.map { |t| team_json(t) }
  end

  # GET /teams/:id  -> a single team with its members (admin only)
  def show
    render json: team_json(@team).merge(members: @team.users.order(:id).map { |u| member_json(u) })
  end

  # POST /teams  -> create a team and affect it to a project (admin only)
  def create
    team = Team.new(name: params[:name], project_id: params[:project_id], manager_id: params[:manager_id])

    if team.save
      render json: team_json(team), status: :created
    else
      render json: { errors: team.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /teams/:id  -> rename and/or (re)affect to a project (admin only)
  def update
    @team.name = params[:name] if params.key?(:name)
    @team.project_id = params[:project_id] if params.key?(:project_id)
    @team.manager_id = params[:manager_id] if params.key?(:manager_id)

    if @team.save
      render json: team_json(@team)
    else
      render json: { errors: @team.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /teams/:id  -> remove a team; members are un-assigned (admin only)
  def destroy
    @team.destroy
    head :no_content
  end

  # GET /teams/mine  -> team + colleagues of the current user.
  def mine
    return render json: { team: nil, members: [] }, status: :ok unless current_user.team

    members = current_user.team.users.where.not(id: current_user.id)
    render json: {
      team: { id: current_user.team.id, name: current_user.team.name },
      members: members.map { |u| member_json(u) }
    }, status: :ok
  end

  private

  def set_team
    @team = Team.find_by(id: params[:id])
    render json: { error: "Équipe introuvable" }, status: :not_found unless @team
  end

  # Public representation of a team (admin views).
  def team_json(team)
    {
      id: team.id,
      name: team.name,
      project_id: team.project_id,
      project: team.project && { id: team.project.id, name: team.project.name },
      business_unit: team.project&.business_unit && { id: team.project.business_unit.id, name: team.project.business_unit.name },
      member_count: team.users.count,
    }
  end
end
