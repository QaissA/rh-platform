# Best-effort POST to auth-service. Failures must never block leave/document flows.
require "net/http"
require "json"

class NotificationClient
  def self.notify(user_id:, kind:, title:, body:, link:)
    new.notify(user_id:, kind:, title:, body:, link:)
  end

  def notify(user_id:, kind:, title:, body:, link:)
    base = ENV["AUTH_SERVICE_URL"].to_s.strip
    return if base.blank?

    uri = URI.parse("#{base.chomp("/")}/internal/notifications")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 2
    http.read_timeout = 3

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json"
    req["X-Internal-Token"] = ENV.fetch("INTERNAL_TOKEN", "dev-internal-token")
    req.body = { user_id:, kind:, title:, body:, link: }.to_json

    res = http.request(req)
    Rails.logger.warn("[notifications] auth-service #{res.code}: #{res.body}") unless res.is_a?(Net::HTTPSuccess)
  rescue StandardError => e
    Rails.logger.warn("[notifications] #{e.class}: #{e.message}")
  end
end
