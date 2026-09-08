# frozen_string_literal: true

require "test_helper"

class JobTitleWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @employee = create_user(pending_job_title: "Comptable")
    @rh = create_user(role: "rh")
  end

  test "RH accept copies pending title onto the user" do
    post "/users/#{@employee.id}/job-title/accept",
         headers: auth_headers(@rh),
         as: :json
    assert_response :success
    @employee.reload
    assert_equal "Comptable", @employee.job_title
    assert_nil @employee.pending_job_title
  end

  test "RH reject clears the pending title without setting job_title" do
    post "/users/#{@employee.id}/job-title/reject",
         params: { comment: "Poste inexistant" },
         headers: auth_headers(@rh),
         as: :json
    assert_response :success
    @employee.reload
    assert_nil @employee.job_title
    assert_nil @employee.pending_job_title
  end
end
