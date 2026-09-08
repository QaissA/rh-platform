# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
if (url = ENV["DATABASE_URL"]) && url.include?("_development")
  ENV["DATABASE_URL"] = url.sub("_development", "_test")
end
# Document decisions notify auth-service; tests must not depend on that HTTP call.
ENV["AUTH_SERVICE_URL"] = ""

require_relative "../config/environment"
require "rails/test_help"

class ActionDispatch::IntegrationTest
  def json_body
    JSON.parse(response.body)
  end

  def doc_headers(user_id:, role:)
    {
      "X-User-Id" => user_id.to_s,
      "X-User-Role" => role,
    }
  end
end
