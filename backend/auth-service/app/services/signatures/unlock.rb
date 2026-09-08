# frozen_string_literal: true

module Signatures
  class Unlock
    class Error < StandardError; end

    def self.call(user)
      raise Error, "Aucune signature à déverrouiller" if user.signature_png.blank?

      user.update!(signature_locked: false)
      Notifications::Deliver.call(
        user,
        kind: "signature_unlocked",
        title: "Vous pouvez mettre à jour votre signature",
        body: "La RH a autorisé une nouvelle signature. Rendez-vous dans Paramètres.",
        link: "/parametres",
      )
      user
    end
  end
end
