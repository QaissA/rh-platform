# frozen_string_literal: true

require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  setup do
    @ada = create_user(first_name: "Ada", last_name: "Martin")
    @bob = create_user(first_name: "Bob", last_name: "Durand")
  end

  test "GET /notifications returns only the current user's notifications" do
    mine = Notification.create!(
      user: @ada,
      kind: "document_ready",
      title: "Votre bulletin est pret",
      body: "Janvier 2026",
      link: "/documents/1",
    )
    Notification.create!(
      user: @bob,
      kind: "leave_hr_approved",
      title: "Congé validé",
      body: "Du 1 au 5",
    )

    get "/notifications", headers: auth_headers(@ada)
    assert_response :success
    assert_kind_of Array, json_body

    ids = json_body.map { |n| n["id"] }
    assert_equal [mine.id], ids
  end

  test "GET /notifications requires authentication" do
    get "/notifications"
    assert_response :unauthorized
  end
end
