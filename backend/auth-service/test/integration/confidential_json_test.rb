# frozen_string_literal: true

require "test_helper"

class ConfidentialJsonTest < ActionDispatch::IntegrationTest
  setup do
    @employee = create_user(
      first_name: "Emma",
      last_name: "Martin",
      salary_cents: 320_000,
      iban: "FR7630006000011234567890189",
      job_title: "Développeuse",
    )
  end

  test "GET /me never includes salary or iban" do
    get "/me", headers: auth_headers(@employee)
    assert_response :success
    body = json_body
    assert_equal "Développeuse", body["job_title"]
    refute body.key?("salary_cents")
    refute body.key?("iban")
  end

  test "GET /profile never includes salary or iban" do
    get "/profile", headers: auth_headers(@employee)
    assert_response :success
    body = json_body
    assert_equal "Développeuse", body["job_title"]
    refute body.key?("salary_cents")
    refute body.key?("iban")
  end

  test "employee cannot read another user's dossier" do
    other = create_user
    get "/users/#{other.id}", headers: auth_headers(@employee)
    assert_response :forbidden
  end
end
