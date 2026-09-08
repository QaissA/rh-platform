# frozen_string_literal: true

require "test_helper"

class RhCannotPatchRoleTest < ActionDispatch::IntegrationTest
  test "RH can update salary but cannot change app role" do
    rh = create_user(role: "rh", first_name: "Camille", last_name: "RH")
    employee = create_user(role: "employee", salary_cents: 200_000)

    patch "/users/#{employee.id}",
          params: { role: "admin", salary_cents: 250_000 },
          headers: auth_headers(rh),
          as: :json

    assert_response :success
    employee.reload
    assert_equal "employee", employee.role
    assert_equal 250_000, employee.salary_cents
    refute json_body.key?("role") && json_body["role"] == "admin"
    assert_equal "employee", json_body["role"]
  end
end
