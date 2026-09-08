class NotificationMailer < ApplicationMailer
  def alert(user, notification)
    @notification = notification
    mail(to: user.email, subject: notification.title) do |format|
      format.text do
        render plain: [
          notification.body,
          "",
          "Ouvrez Alizé : http://localhost:4300#{notification.link}",
        ].compact.join("\n")
      end
    end
  end
end
