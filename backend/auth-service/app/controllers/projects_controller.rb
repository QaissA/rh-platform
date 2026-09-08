class ProjectsController < ApplicationController
  before_action :require_admin!
  before_action :set_project, only: [:show, :update, :destroy]

  # GET /projects  -> all projects, optionally filtered by ?business_unit_id= (admin only)
  def index
    scope = Project.all
    scope = scope.where(business_unit_id: params[:business_unit_id]) if params[:business_unit_id].present?
    render json: scope.order(:name).map { |p| project_json(p) }
  end

  # GET /projects/:id  -> a project with its members (admin only)
  def show
    render json: project_json(@project).merge(
      members: @project.members.order(:id).map { |u| member_json(u) },
    )
  end

  # POST /projects  -> create a project under a BU, optionally with a lead (admin only)
  def create
    project = Project.new(name: params[:name], business_unit_id: params[:business_unit_id], lead_id: params[:lead_id])

    if project.save
      render json: project_json(project), status: :created
    else
      render json: { errors: project.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /projects/:id  -> rename, move BU, and/or (re)assign the lead
  def update
    @project.name = params[:name] if params.key?(:name)
    @project.business_unit_id = params[:business_unit_id] if params.key?(:business_unit_id)
    @project.lead_id = params[:lead_id] if params.key?(:lead_id)

    if @project.save
      render json: project_json(@project)
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /projects/:id  -> remove a project; its members are freed
  def destroy
    @project.destroy
    head :no_content
  end

  private

  def set_project
    @project = Project.find_by(id: params[:id])
    render json: { error: "Projet introuvable" }, status: :not_found unless @project
  end

  def project_json(project)
    {
      id: project.id,
      name: project.name,
      business_unit_id: project.business_unit_id,
      business_unit: project.business_unit && { id: project.business_unit.id, name: project.business_unit.name },
      lead_id: project.lead_id,
      lead: project.lead && member_json(project.lead),
      member_count: project.members.count,
    }
  end
end
