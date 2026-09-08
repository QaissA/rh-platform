# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user_id

    def connect
      claims = JsonWebToken.decode(request.params[:token].to_s)
      reject_unauthorized_connection unless claims && claims[:user_id]
      self.current_user_id = claims[:user_id].to_i
    end
  end
end
