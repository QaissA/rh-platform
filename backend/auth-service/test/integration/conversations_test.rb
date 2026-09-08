# frozen_string_literal: true

require "test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  setup do
    @ada = create_user(first_name: "Ada", last_name: "Martin")
    @bob = create_user(first_name: "Bob", last_name: "Durand", salary_cents: 9_999, iban: "FR76X")
    @eve = create_user(first_name: "Eve", last_name: "Leroy")
  end

  test "POST /conversations creates a 1:1 thread" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    assert_response :created
    assert_equal @bob.id, json_body["other"]["id"]
    refute json_body["other"].key?("salary_cents")
  end

  test "POST /conversations is idempotent for the same pair" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    first_id = json_body["id"]
    post "/conversations", params: { user_id: @ada.id }, headers: auth_headers(@bob), as: :json
    assert_includes [200, 201], response.status
    assert_equal first_id, json_body["id"]
  end

  test "cannot open a conversation with yourself" do
    post "/conversations", params: { user_id: @ada.id }, headers: auth_headers(@ada), as: :json
    assert_response :unprocessable_content
  end

  test "sending a message increments the recipient unread count" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    conv_id = json_body["id"]

    post "/conversations/#{conv_id}/messages",
         params: { body: "Salut" },
         headers: auth_headers(@ada),
         as: :json
    assert_response :created
    assert_equal "Salut", json_body["body"]
    assert_equal @ada.id, json_body["sender_id"]

    get "/conversations", headers: auth_headers(@bob)
    assert_response :success
    thread = json_body.find { |c| c["id"] == conv_id }
    assert_equal 1, thread["unread_count"]
    assert_equal "Salut", thread["last_message"]["body"]
    refute thread["other"].key?("iban")
  end

  test "POST /conversations/:id/read clears unread for the reader" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    conv_id = json_body["id"]
    post "/conversations/#{conv_id}/messages",
         params: { body: "Salut" },
         headers: auth_headers(@ada),
         as: :json

    post "/conversations/#{conv_id}/read", headers: auth_headers(@bob), as: :json
    assert_response :success

    get "/conversations", headers: auth_headers(@bob)
    thread = json_body.find { |c| c["id"] == conv_id }
    assert_equal 0, thread["unread_count"]
  end

  test "a third user cannot read the thread" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    conv_id = json_body["id"]

    get "/conversations/#{conv_id}/messages", headers: auth_headers(@eve)
    assert_response :forbidden
  end

  test "can attach a PNG and the recipient can download it" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    conv_id = json_body["id"]

    post "/conversations/#{conv_id}/messages",
         params: { body: "Scan", file: png_upload },
         headers: auth_headers(@ada)
    assert_response :created
    assert_equal "Scan", json_body["body"]
    assert_equal "scan.png", json_body["attachment"]["filename"]
    assert_equal "image/png", json_body["attachment"]["content_type"]
    msg_id = json_body["id"]

    get "/conversations/#{conv_id}/messages/#{msg_id}/file", headers: auth_headers(@bob)
    assert_response :success
    assert_equal "image/png", response.media_type

    get "/conversations/#{conv_id}/messages/#{msg_id}/file", headers: auth_headers(@eve)
    assert_response :forbidden
  end

  test "file-only message is allowed" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    conv_id = json_body["id"]
    post "/conversations/#{conv_id}/messages",
         params: { file: png_upload },
         headers: auth_headers(@ada)
    assert_response :created
    assert json_body["attachment"].present?
  end

  test "rejects a non image/pdf file" do
    post "/conversations", params: { user_id: @bob.id }, headers: auth_headers(@ada), as: :json
    conv_id = json_body["id"]
    txt = Tempfile.new(["note", ".txt"])
    txt.write("hello")
    txt.rewind
    upload = Rack::Test::UploadedFile.new(txt.path, "text/plain", original_filename: "note.txt")
    post "/conversations/#{conv_id}/messages",
         params: { file: upload },
         headers: auth_headers(@ada)
    assert_response :unprocessable_content
  end
end
