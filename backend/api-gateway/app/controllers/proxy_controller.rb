class ProxyController < ApplicationController
  # Requests that do NOT require a valid JWT (prefix + first path segment).
  PUBLIC_ROUTES = [
    ["auth", "login"]
  ].freeze

  # Catch-all: forwards /<prefix>/<path> to the matching downstream service.
  def forward
    prefix = params[:prefix]
    path = params[:path].to_s
    # Inter-service only: leave-service and admin-doc-service talk to auth-service directly.
    return render json: { error: "Not found" }, status: :not_found if prefix == "auth" && path.start_with?("internal/")

    base_url = ServiceRegistry.base_url_for(prefix)

    return render json: { error: "Unknown service" }, status: :not_found unless base_url

    claims = authenticate!(prefix, path)
    return if performed? # authenticate! already rendered a 401

    # Preserve the query string so downstream filters (?status=, ?business_unit_id=) work.
    downstream_path = request.query_string.empty? ? "/#{path}" : "/#{path}?#{request.query_string}"

    response = downstream(base_url).run_request(
      request.request_method_symbol,
      downstream_path,
      forward_body,
      forward_headers(claims)
    )

    render json: response.body, status: response.status
  rescue Faraday::ConnectionFailed
    render json: { error: "Service unavailable" }, status: :bad_gateway
  end

  private

  def public_route?(prefix, path)
    PUBLIC_ROUTES.include?([prefix, path.split("/").first])
  end

  # Returns decoded claims, or renders 401 and returns nil.
  def authenticate!(prefix, path)
    return nil if public_route?(prefix, path)

    token = request.authorization.to_s.split(" ").last
    claims = token && JsonWebToken.decode(token)

    unless claims
      render json: { error: "Unauthorized" }, status: :unauthorized
      return nil
    end

    claims
  end

  def downstream(base_url)
    Faraday.new(url: base_url)
  end

  def forward_body
    request.get? || request.head? ? nil : request.raw_post
  end

  def forward_headers(claims)
    headers = { "Content-Type" => request.content_type || "application/json" }
    if claims
      headers["X-User-Id"] = claims[:user_id].to_s
      headers["X-User-Role"] = claims[:role].to_s
      headers["X-User-Team-Id"] = claims[:team_id].to_s
      headers["X-Managed-Team-Ids"] = Array(claims[:managed_team_ids]).join(",")
      headers["X-User-Bu-Id"] = claims[:business_unit_id].to_s
      headers["X-User-Project-Id"] = claims[:project_id].to_s
      headers["X-Led-Project-Ids"] = Array(claims[:led_project_ids]).join(",")
      headers["X-Managed-Bu-Ids"] = Array(claims[:managed_bu_ids]).join(",")
    end
    headers
  end
end
