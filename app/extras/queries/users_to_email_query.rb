class Queries::UsersToEmailQuery
  def self.new_comment(comment)
    Queries::UsersByVolumeQuery.loud(comment.discussion).
                       distinct.
                       without(comment.author).
                       without(comment.mentioned_group_members).
                       without(comment.parent_author)
  end

  def self.new_vote(vote)
    Queries::UsersByVolumeQuery.loud(vote.motion.discussion).
                       distinct.
                       without(vote.author)
  end

  def self.new_discussion(discussion)
    Queries::UsersByVolumeQuery.normal_or_loud(discussion).
                       distinct.
                       without(discussion.author).
                       without(discussion.mentioned_group_members)
  end

  def self.new_motion(motion)
    Queries::UsersByVolumeQuery.normal_or_loud(motion.discussion).
                       distinct.
                       without(motion.author).
                       without(motion.mentioned_group_members)
  end

  def self.motion_closing_soon(motion)
    User.distinct.where.any_of(Queries::UsersByVolumeQuery.normal_or_loud(motion.discussion),
                               User.email_proposal_closing_soon_for(motion.group))
  end

  def self.motion_outcome_created(motion)
    Queries::UsersByVolumeQuery.normal_or_loud(motion.discussion).
                       distinct.
                       without(motion.outcome_author)
  end

  def self.motion_closed(motion)
    Queries::UsersByVolumeQuery.normal_or_loud(motion.discussion).distinct
  end

  def self.poll_create(poll)
    return User.none unless poll.make_announcement
    listeners_for(poll).without(poll.author)
  end

  def self.poll_update(poll)
    return User.none unless poll.make_announcement
    poll.voters
  end

  def self.poll_closing_soon(poll)
    listeners_for(poll).without(poll.voters)
  end

  def self.outcome_create(outcome)
    return User.none unless outcome.make_announcement
    listeners_for(outcome.poll).without(outcome.author) # maybe just poll voters?
  end

  def self.outcome_update(outcome)
    return User.none unless outcome.make_announcement
    listeners_for(outcome.poll).without(outcome.author)
  end

  # this should probably end up as poll.listeners somehow
  def self.listeners_for(poll)
    if poll.discussion
      Queries::UsersByVolumeQuery.normal_or_loud(poll.discussion).distinct
    else
      # TODO: look at poll communities for interested parties
    end
  end
  private_class_method :listeners_for
end
