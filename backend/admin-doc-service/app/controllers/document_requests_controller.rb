class DocumentRequestsController < ApplicationController
  before_action :require_user!
  before_action :require_hr!, only: [:inbox]
  before_action :set_request, only: [:show, :update]

  # GET /requests  -> current user's administrative paper requests
  def index
    requests = DocumentRequest.where(user_id: current_user_id).order(created_at: :desc)
    render json: requests.map { |r| request_json(r, fields: r.ready?) }
  end

  # GET /requests/inbox  -> all requests, for RH / admin
  def inbox
    requests = DocumentRequest.all.order(created_at: :desc)
    requests = requests.where(status: params[:status]) if params[:status].present?
    render json: requests.map { |r| request_json(r, fields: true) }
  end

  # GET /requests/:id
  def show
    return unless can_read?(@request)

    include_fields = hr_officer? || @request.ready?
    render json: request_json(@request, fields: include_fields)
  end

  # POST /requests  -> submit a new administrative paper request
  def create
    doc_request = DocumentRequest.new(create_params)
    doc_request.user_id = current_user_id

    if doc_request.save
      render json: request_json(doc_request, fields: false), status: :created
    else
      render json: { errors: doc_request.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH /requests/:id  -> RH saves template fields and/or changes status
  def update
    return render json: { error: "Accès réservé à la RH" }, status: :forbidden unless hr_officer?
    return render json: { error: "Demande introuvable" }, status: :not_found unless @request

    becoming_ready = params[:status] == "ready" && !@request.ready?

    @request.fields = sanitized_fields if params.key?(:fields)
    if params[:status].present?
      return render json: { error: "Statut invalide" }, status: :unprocessable_content unless DocumentRequest.statuses.key?(params[:status])

      @request.status = params[:status]
      if @request.ready?
        @request.issued_by = current_user_id
        @request.issued_at = Time.current
      end
    end
    @request.decision_comment = params[:decision_comment] if params.key?(:decision_comment)

    if @request.save
      notify_document_ready if becoming_ready
      render json: request_json(@request, fields: true)
    else
      render json: { errors: @request.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_request
    @request = DocumentRequest.find_by(id: params[:id])
    render json: { error: "Demande introuvable" }, status: :not_found unless @request
  end

  def can_read?(req)
    return true if hr_officer?
    return true if req.user_id.to_s == current_user_id.to_s

    render json: { error: "Accès refusé" }, status: :forbidden
    false
  end

  def create_params
    params.permit(:doc_type, :note)
  end

  def sanitized_fields
    raw = params[:fields]
    raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
    raw = {} unless raw.is_a?(Hash)
    raw.stringify_keys.slice(*DocumentRequest::FIELD_KEYS)
  end

  def request_json(r, fields:)
    json = {
      id: r.id,
      user_id: r.user_id,
      doc_type: r.doc_type,
      status: r.status,
      note: r.note,
      issued_at: r.issued_at,
      decision_comment: r.decision_comment,
    }
    json[:fields] = r.fields.presence || {} if fields
    json
  end

  def notify_document_ready
    NotificationClient.notify(
      user_id: @request.user_id,
      kind: "document_ready",
      title: "Votre document est prêt",
      body: "La RH a mis votre document administratif à disposition. Vous pouvez le télécharger.",
      link: "/documents/#{@request.id}",
    )
  end
end
