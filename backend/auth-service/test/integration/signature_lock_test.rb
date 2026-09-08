# frozen_string_literal: true

require "test_helper"

class SignatureLockTest < ActionDispatch::IntegrationTest
  setup do
    @employee = create_user
    @rh = create_user(role: "rh")
  end

  test "saving a signature locks it; a second save is forbidden until RH unlocks" do
    patch "/profile",
          params: { signature_png: TINY_PNG },
          headers: auth_headers(@employee),
          as: :json
    assert_response :success
    assert_equal true, json_body["signature_locked"]
    assert @employee.reload.signature_locked?

    patch "/profile",
          params: { signature_png: TINY_PNG },
          headers: auth_headers(@employee),
          as: :json
    assert_response :forbidden

    post "/users/#{@employee.id}/signature/unlock",
         headers: auth_headers(@rh),
         as: :json
    assert_response :success
    assert_equal false, json_body["signature_locked"]

    patch "/profile",
          params: { signature_png: TINY_PNG },
          headers: auth_headers(@employee),
          as: :json
    assert_response :success
    assert_equal true, json_body["signature_locked"]
  end

  test "unlock without a signature is rejected" do
    post "/users/#{@employee.id}/signature/unlock",
         headers: auth_headers(@rh),
         as: :json
    assert_response :unprocessable_content
  end
end
