# frozen_string_literal: true

require "test_helper"

class DirectoryTest < ActionDispatch::IntegrationTest
  test "GET /directory lists other users without pay fields" do
    me = create_user(first_name: "Ada")
    other = create_user(first_name: "Bob", salary_cents: 9_999, iban: "FR76X")

    get "/directory", headers: auth_headers(me)

    assert_response :success
    ids = json_body.map { |u| u["id"] }
    assert_includes ids, other.id
    refute_includes ids, me.id
    bob = json_body.find { |u| u["id"] == other.id }
    refute bob.key?("salary_cents")
    refute bob.key?("iban")
  end

  test "GET /directory requires authentication" do
    get "/directory"
    assert_response :unauthorized
  end
end
