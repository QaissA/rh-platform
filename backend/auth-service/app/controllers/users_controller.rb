class UsersController < ApplicationController
  before_action :require_admin_or_rh!, only: [:index, :show, :update, :reset_password, :accept_job_title, :reject_job_title, :unlock_signature]
  before_action :require_admin!, only: [:create, :destroy]
  before_action :set_user, only: [:show, :update, :destroy, :reset_password, :accept_job_title, :reject_job_title, :unlock_signature]

  def index
    users = User.order(:id)
    render json: users.map { |u| user_json(u) }
  end

  def show
    render json: dossier_json(@user)
  end

  def create
    role = params[:role].presence || "employee"
    return render_invalid_role unless User::ROLES.include?(role)

    temporary_password = PasswordGenerator.generate

    user = User.new(
      email: params[:email],
      password: temporary_password,
      first_name: params[:first_name],
      last_name: params[:last_name],
      role: role,
      team_id: params[:team_id],
      business_unit_id: params[:business_unit_id],
      project_id: params[:project_id],
      must_change_password: true,
    )

    if user.save
      render json: user_json(user).merge(temporary_password: temporary_password), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    apply_admin_org_fields if current_user.admin?
    apply_profile_fields
    apply_confidential_fields

    if @user.save
      render json: dossier_json(@user)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def accept_job_title
    JobTitles::Accept.call(@user)
    render json: dossier_json(@user)
  rescue JobTitles::Accept::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def reject_job_title
    JobTitles::Reject.call(@user, comment: params[:comment])
    render json: dossier_json(@user)
  rescue JobTitles::Reject::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def unlock_signature
    Signatures::Unlock.call(@user)
    render json: dossier_json(@user)
  rescue Signatures::Unlock::Error => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def reset_password
    temporary_password = PasswordGenerator.generate
    @user.password = temporary_password
    @user.must_change_password = true

    if @user.save
      render json: user_json(@user).merge(temporary_password: temporary_password)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @user.id == current_user.id
      return render json: { error: "Vous ne pouvez pas supprimer votre propre compte" },
                    status: :unprocessable_content
    end
    if @user.last_admin?
      return render json: { error: "Impossible de supprimer le dernier administrateur" },
                    status: :unprocessable_content
    end

    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    render json: { error: "Utilisateur introuvable" }, status: :not_found unless @user
  end

  def apply_admin_org_fields
    if params.key?(:role)
      return unless User::ROLES.include?(params[:role])
      if demoting_last_admin?(params[:role])
        @user.errors.add(:role, "impossible de rétrograder le dernier administrateur")
        return
      end
      @user.role = params[:role]
    end
    @user.team_id = params[:team_id] if params.key?(:team_id)
    @user.business_unit_id = params[:business_unit_id] if params.key?(:business_unit_id)
    @user.project_id = params[:project_id] if params.key?(:project_id)
    @user.password = params[:password] if params[:password].present?
  end

  def apply_profile_fields
    @user.first_name = params[:first_name] if params.key?(:first_name)
    @user.last_name = params[:last_name] if params.key?(:last_name)
    @user.address_line = params[:address_line] if params.key?(:address_line)
    @user.postal_code = params[:postal_code] if params.key?(:postal_code)
    @user.city = params[:city] if params.key?(:city)
    @user.country = params[:country] if params.key?(:country)
    if params.key?(:job_title)
      @user.job_title = params[:job_title].to_s.strip.presence
      @user.pending_job_title = nil
    end
  end

  def apply_confidential_fields
    @user.salary_cents = params[:salary_cents] if params.key?(:salary_cents)
    @user.contract_type = params[:contract_type].presence if params.key?(:contract_type)
    @user.hired_on = params[:hired_on].presence if params.key?(:hired_on)
    @user.iban = params[:iban] if params.key?(:iban)
  end

  def demoting_last_admin?(new_role)
    @user.last_admin? && new_role != "admin"
  end

  def render_invalid_role
    render json: { error: "Rôle invalide (attendu : #{User::ROLES.join(', ')})" },
           status: :unprocessable_content
  end
end
