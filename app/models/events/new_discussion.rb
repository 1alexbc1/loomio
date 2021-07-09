class Events::NewDiscussion < Event
  include Events::LiveUpdate
  include Events::Notify::InApp
  include Events::Notify::ByEmail
  include Events::Notify::Mentions
  include Events::Notify::ThirdParty

  def self.publish!(discussion:, recipient_user_ids: [], recipient_audience: nil)
    super(discussion, user: discussion.author,
          recipient_user_ids: recipient_user_ids,
          recipient_audience: recipient_audience)
  end

  def discussion
    eventable
  end
end
