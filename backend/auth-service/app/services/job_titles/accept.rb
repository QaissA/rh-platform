# frozen_string_literal: true

module JobTitles
  class Accept
    class Error < StandardError; end

    def self.call(user)
      pending = user.pending_job_title.to_s.strip
      raise Error, "Aucune demande de poste en attente" if pending.blank?

      user.update!(job_title: pending, pending_job_title: nil)
      Notifications::Deliver.call(
        user,
        kind: "job_title_approved",
        title: "Votre poste a été confirmé",
        body: "La RH a validé le poste « #{user.job_title} ».",
        link: "/parametres",
      )
      user
    end
  end
end
