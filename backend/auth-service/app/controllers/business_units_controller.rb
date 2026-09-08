class BusinessUnitsController < ApplicationController
  before_action :require_admin!
  before_action :set_business_unit, only: [:show, :update, :destroy]

  # GET /business-units  -> all BUs with counts (admin only)
  def index
    render json: BusinessUnit.order(:name).map { |b| bu_json(b) }
  end

  # GET /business-units/:id  -> a BU with its projects and members (admin only)
  def show
    render json: bu_json(@bu).merge(
      projects: @bu.projects.order(:name).map { |p| project_brief(p) },
      members: @bu.users.order(:id).map { |u| member_json(u) },
    )
  end

  # POST /business-units  -> create a BU, optionally with a manager (admin only)
  def create
    bu = BusinessUnit.new(name: params[:name], manager_id: params[:manager_id])

    if bu.save
      render json: bu_json(bu), status: :created
    else
      render json: { errors: bu.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /business-units/:id  -> rename and/or (re)assign the manager
  def update
    @bu.name = params[:name] if params.key?(:name)
    @bu.manager_id = params[:manager_id] if params.key?(:manager_id)

    if @bu.save
      render json: bu_json(@bu)
    else
      render json: { errors: @bu.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /business-units/:id  -> remove a BU (its projects go too; members freed)
  def destroy
    @bu.destroy
    head :no_content
  end

  private

  def set_business_unit
    @bu = BusinessUnit.find_by(id: params[:id])
    render json: { error: "Business unit introuvable" }, status: :not_found unless @bu
  end

  def bu_json(bu)
    {
      id: bu.id,
      name: bu.name,
      manager_id: bu.manager_id,
      project_count: bu.projects.count,
      member_count: bu.users.count,
      manager: bu.manager && member_json(bu.manager),
    }
  end

  def project_brief(project)
    { id: project.id, name: project.name, lead_id: project.lead_id, member_count: project.members.count }
  end
end
