# frozen_string_literal: true

require "test_helper"

class LeaveTwoStepTest < ActionDispatch::IntegrationTest
  TEAM_ID = 7
  EMPLOYEE_ID = 10
  MANAGER_ID = 20
  RH_ID = 30
  OTHER_MANAGER_ID = 40

  # Monday–Tuesday so working_days == 2 regardless of locale.
  START_ON = Date.new(2026, 9, 14)
  END_ON = Date.new(2026, 9, 15)

  setup do
    @leave = LeaveRequest.create!(
      user_id: EMPLOYEE_ID,
      team_id: TEAM_ID,
      start_date: START_ON,
      end_date: END_ON,
      reason: "Congés",
      status: "pending",
    )
    @balance = LeaveBalance.create!(user_id: EMPLOYEE_ID, days_remaining: 25)
  end

  test "manager approve moves pending to pending_hr without debiting" do
    patch "/requests/#{@leave.id}/approve",
          headers: manager_headers,
          as: :json

    assert_response :success
    assert_equal "pending_hr", json_body["status"]
    assert_equal 25, @balance.reload.days_remaining.to_i
    assert_equal "pending_hr", @leave.reload.status
  end

  test "manager cannot approve a request already at pending_hr" do
    @leave.update!(status: "pending_hr")

    patch "/requests/#{@leave.id}/approve",
          headers: manager_headers,
          as: :json

    assert_response :forbidden
    assert_equal "pending_hr", @leave.reload.status
    assert_equal 25, @balance.reload.days_remaining.to_i
  end

  test "RH approve of pending_hr marks approved and debits the balance" do
    @leave.update!(status: "pending_hr")

    patch "/requests/#{@leave.id}/approve",
          headers: rh_headers,
          as: :json

    assert_response :success
    assert_equal "approved", json_body["status"]
    assert_equal "approved", @leave.reload.status
    assert_equal 23, @balance.reload.days_remaining.to_i
  end

  test "manager of another team cannot approve" do
    patch "/requests/#{@leave.id}/approve",
          headers: leave_headers(user_id: OTHER_MANAGER_ID, role: "manager", managed_team_ids: [99]),
          as: :json

    assert_response :forbidden
    assert_equal "pending", @leave.reload.status
  end

  test "manager can reject a pending request" do
    patch "/requests/#{@leave.id}/reject",
          params: { comment: "Période fermée" },
          headers: manager_headers,
          as: :json

    assert_response :success
    assert_equal "rejected", json_body["status"]
    assert_equal "Période fermée", json_body["decision_comment"]
    assert_equal 25, @balance.reload.days_remaining.to_i
  end

  test "RH can reject a pending_hr request" do
    @leave.update!(status: "pending_hr")

    patch "/requests/#{@leave.id}/reject",
          headers: rh_headers,
          as: :json

    assert_response :success
    assert_equal "rejected", @leave.reload.status
  end

  private

  def manager_headers
    leave_headers(user_id: MANAGER_ID, role: "manager", managed_team_ids: [TEAM_ID])
  end

  def rh_headers
    leave_headers(user_id: RH_ID, role: "rh")
  end
end
