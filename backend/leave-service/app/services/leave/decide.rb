# frozen_string_literal: true

module Leave
  class Decide
    Result = Data.define(:ok, :error, :status) do
      def self.ok
        new(ok: true, error: nil, status: :ok)
      end

      def self.fail(error, status)
        new(ok: false, error: error, status: status)
      end
    end

    Actor = Data.define(:id, :role, :managed_team_ids) do
      def admin? = role == "admin"
      def rh? = role == "rh"
      def manager? = role == "manager"
    end

    def initialize(request:, actor:)
      @request = request
      @actor = actor
    end

    def approve
      return Result.fail("Accès refusé", :forbidden) unless can_decide?
      return Result.fail("Demande déjà traitée", :unprocessable_content) unless @request.awaiting?

      if @request.pending?
        @request.update!(status: "pending_hr", decided_by: @actor.id, decided_at: Time.current)
        notify(
          "leave_manager_approved",
          "Votre manager a accepté votre congé",
          "Votre demande est transmise à la RH pour confirmation.",
        )
        return Result.ok
      end

      ActiveRecord::Base.transaction do
        balance = LeaveBalance.find_or_create_by!(user_id: @request.user_id)
        balance.update!(days_remaining: balance.days_remaining - @request.working_days)
        @request.update!(status: "approved", decided_by: @actor.id, decided_at: Time.current)
      end

      notify(
        "leave_hr_approved",
        "Votre congé est confirmé",
        "La RH a validé votre demande. Le solde a été débité.",
      )
      Result.ok
    rescue ActiveRecord::RecordInvalid
      Result.fail("Solde insuffisant", :unprocessable_content)
    end

    def reject(comment: nil)
      return Result.fail("Accès refusé", :forbidden) unless can_decide?
      return Result.fail("Demande déjà traitée", :unprocessable_content) unless @request.awaiting?

      @request.update!(
        status: "rejected",
        decided_by: @actor.id,
        decided_at: Time.current,
        decision_comment: comment,
      )
      Result.ok
    end

    private

    def can_decide?
      if @request.pending?
        @actor.admin? || (@actor.manager? && @actor.managed_team_ids.include?(@request.team_id))
      elsif @request.pending_hr?
        @actor.admin? || @actor.rh?
      else
        false
      end
    end

    def notify(kind, title, body)
      NotificationClient.notify(
        user_id: @request.user_id,
        kind: kind,
        title: title,
        body: body,
        link: "/conges",
      )
    end
  end
end
