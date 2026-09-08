# frozen_string_literal: true

require "test_helper"

class DocumentRequestDecisionsTest < ActionDispatch::IntegrationTest
  EMPLOYEE_ID = 10
  OTHER_ID = 11
  RH_ID = 30

  setup do
    @doc = DocumentRequest.create!(
      user_id: EMPLOYEE_ID,
      doc_type: "work_certificate",
      note: "Pour un prêt",
      status: "pending",
    )
  end

  test "owner can cancel a pending request" do
    patch "/requests/#{@doc.id}/cancel", headers: employee_headers, as: :json

    assert_response :success
    assert_equal "cancelled", json_body["status"]
    assert_equal "cancelled", @doc.reload.status
  end

  test "owner can cancel a processing request" do
    @doc.update!(status: "processing")

    patch "/requests/#{@doc.id}/cancel", headers: employee_headers, as: :json

    assert_response :success
    assert_equal "cancelled", @doc.reload.status
  end

  test "another employee cannot cancel someone else's request" do
    patch "/requests/#{@doc.id}/cancel",
          headers: doc_headers(user_id: OTHER_ID, role: "employee"),
          as: :json

    assert_response :forbidden
    assert_equal "pending", @doc.reload.status
  end

  test "owner cannot cancel a ready request" do
    @doc.update!(status: "ready")

    patch "/requests/#{@doc.id}/cancel", headers: employee_headers, as: :json

    assert_response :unprocessable_content
    assert_equal "ready", @doc.reload.status
  end

  test "RH can reject a pending request with a comment" do
    patch "/requests/#{@doc.id}/reject",
          params: { comment: "Pièce insuffisante" },
          headers: rh_headers,
          as: :json

    assert_response :success
    assert_equal "rejected", json_body["status"]
    assert_equal "Pièce insuffisante", json_body["decision_comment"]
    assert_equal "rejected", @doc.reload.status
  end

  test "admin can reject a processing request" do
    @doc.update!(status: "processing")

    patch "/requests/#{@doc.id}/reject",
          headers: doc_headers(user_id: 1, role: "admin"),
          as: :json

    assert_response :success
    assert_equal "rejected", @doc.reload.status
  end

  test "employee cannot reject a request" do
    patch "/requests/#{@doc.id}/reject", headers: employee_headers, as: :json

    assert_response :forbidden
    assert_equal "pending", @doc.reload.status
  end

  test "RH cannot reject a ready request" do
    @doc.update!(status: "ready")

    patch "/requests/#{@doc.id}/reject", headers: rh_headers, as: :json

    assert_response :unprocessable_content
    assert_equal "ready", @doc.reload.status
  end

  test "RH cannot update a cancelled request" do
    @doc.update!(status: "cancelled")

    patch "/requests/#{@doc.id}",
          params: { status: "processing" },
          headers: rh_headers,
          as: :json

    assert_response :unprocessable_content
    assert_equal "cancelled", @doc.reload.status
  end

  private

  def employee_headers
    doc_headers(user_id: EMPLOYEE_ID, role: "employee")
  end

  def rh_headers
    doc_headers(user_id: RH_ID, role: "rh")
  end
end
