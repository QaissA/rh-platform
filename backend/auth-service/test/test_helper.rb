# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
if (url = ENV["DATABASE_URL"]) && url.include?("_development")
  ENV["DATABASE_URL"] = url.sub("_development", "_test")
end

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # One Postgres test DB; avoid parallel workers racing on create/migrate.
  end
end

class ActionDispatch::IntegrationTest
  TINY_PNG = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

  def json_body
    JSON.parse(response.body)
  end

  def auth_headers(user)
    { "X-User-Id" => user.id.to_s }
  end

  def create_user(**attrs)
    n = SecureRandom.hex(4)
    User.create!(
      {
        email: "u#{n}@test.local",
        password: "password",
        first_name: "Test",
        last_name: "User",
        role: "employee",
      }.merge(attrs),
    )
  end

  def png_upload
    raw = Base64.decode64(TINY_PNG.split(",", 2).last)
    file = Tempfile.new(["scan", ".png"])
    file.binmode
    file.write(raw)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "scan.png")
  end
end
