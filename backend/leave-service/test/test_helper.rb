# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
if (url = ENV["DATABASE_URL"]) && url.include?("_development")
  ENV["DATABASE_URL"] = url.sub("_development", "_test")
end
# Leave decisions notify auth-service; tests must not depend on that HTTP call.
ENV["AUTH_SERVICE_URL"] = ""

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # One Postgres test DB; avoid parallel workers racing on create/migrate.
  end
end

class ActionDispatch::IntegrationTest
  def json_body
    JSON.parse(response.body)
  end

  def leave_headers(user_id:, role:, team_id: nil, managed_team_ids: [])
    {
      "X-User-Id" => user_id.to_s,
      "X-User-Role" => role,
      "X-User-Team-Id" => team_id.to_s,
      "X-Managed-Team-Ids" => Array(managed_team_ids).join(","),
    }
  end
end
