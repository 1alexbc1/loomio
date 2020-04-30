class PollMailer < BaseMailer
  helper :email
  REPLY_DELIMITER = "--"

  def poll_created(poll)
    send_poll_mail poll: poll, recipients: Queries::UsersToEmailQuery.poll_create(poll)
  end

  def poll_updated(poll)
    send_poll_mail poll: poll, recipients: Queries::UsersToEmailQuery.poll_update(poll)
  end

  def poll_closing_soon(poll)
    send_poll_mail poll: poll, recipients: Queries::UsersToEmailQuery.poll_closing_soon(poll)
  end

  def poll_expired(poll)
    send_poll_mail poll: poll, recipients: Queries::UsersToEmailQuery.poll_expired(poll)
  end

  def outcome_create(outcome)
    send_poll_mail poll: outcome.poll, recipients: Queries::UsersToEmailQuery.outcome_create(outcome)
  end

  private

  def send_poll_mail(poll:, recipients:, priority: 2)
    headers = {
      "Precendence":              :bulk,
      "X-Auto-Response-Suppress": :OOF,
      "Auto-Submitted":           :"auto-generated"
    }

    delay(priority: priority).send_bulk_mail(to: recipients) do |recipient|
      @info = PollEmailInfo(poll: poll, recipient: recipient, utm: utm_hash)

      send_single_mail(
        locale:        locale_for(user),
        to:            recipient.email,
        subject_key:   "poll_mailer.#{poll_type}.subject.#{action_name}",
        subject_params: { title: poll.title, actor: poll.author.name }
      )
    end
  end

end
