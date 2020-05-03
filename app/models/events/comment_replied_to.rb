class Events::CommentRepliedTo < Event
  include Events::LiveUpdate
  include Events::NotifyUser
  include Events::EmailUser

  def self.publish!(comment)
    return unless comment.parent && comment.parent.author != comment.author
    create(kind: 'comment_replied_to',
           eventable: comment,
           created_at: comment.created_at).tap { |e| EventBus.broadcast('comment_replied_to_event', e, comment.parent.author_id) }
  end
end
