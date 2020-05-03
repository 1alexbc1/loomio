class Events::PollEdited < Event
  include PollNotificationEvent

  def self.publish!(version, actor, announcement = false)
    create(kind: "poll_edited",
           user: actor,
           eventable: version,
           announcement: announcement,
           discussion: version.item.discussion,
           created_at: version.created_at).tap { |e| EventBus.broadcast('poll_edited_event', e) }
  end

  private

  # notify those who have already participated in the poll of the change
  def announcement_notification_recipients
    eventable.poll.participants
  end
  alias :announcement_email_recipients :announcement_notification_recipients
end
