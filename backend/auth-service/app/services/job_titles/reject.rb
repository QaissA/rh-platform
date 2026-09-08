# frozen_string_literal: true

module JobTitles
  class Reject
    class Error < StandardError; end

    def self.call(user, comment: nil)
      pending = user.pending_job_title.to_s.strip
      raise Error, "Aucune demande de poste en attente" if pending.blank?

      user.update!(pending_job_title: nil)
      body = "La RH a refusé la demande de poste « #{pending} »."
      note = comment.to_s.strip
      body = "#{body} Motif : #{note}" if note.present?
      Notifications::Deliver.call(
        user,
        kind: "job_title_rejected",
        title: "Demande de poste refusée",
        body: body,
        link: "/parametres",
      )
      user
    end
  end
end
