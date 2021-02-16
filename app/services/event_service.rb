class EventService
  def self.remove_from_thread(event:, actor:)
    discussion = event.discussion
    raise CanCan::AccessDenied.new unless event.kind == 'discussion_edited'
    actor.ability.authorize! :remove_events, discussion

    event.update(discussion_id: nil)
    discussion.thread_item_destroyed!
    EventBus.broadcast('event_remove_from_thread', event)
    event
  end

  def self.readd_to_thread(kind:)
    Event.where(kind: kind, discussion_id: nil).where("sequence_id is not null").find_each do |event|
      next unless event.eventable

      if Event.exists?(sequence_id: event.sequence_id, discussion_id: event.eventable.discussion_id)
        Event.where(discussion_id: event.eventable.discussion_id)
             .where("sequence_id >= ?", event.sequence_id)
             .order(sequence_id: :desc)
             .each { |event| event.increment!(:sequence_id) }
      end

      event.update_attribute(:discussion_id, event.eventable.discussion_id)
      event.reload.discussion.update_sequence_info!
    end
  end

  def self.move_comments(discussion:, actor:, params:)
    # handle parent comments = events where parent_id is source.created_event.id
      # move all events which are children of above parents (comment parent id untouched)
    # handle any reply comments that don't have parent_id in given ids

    ids = Array(params[:forked_event_ids]).compact
    source = Event.find(ids.first).discussion

    actor.ability.authorize! :move_comments, source
    actor.ability.authorize! :move_comments, discussion
    Delayed::Job.enqueue MoveCommentsJob.new(ids, source, discussion)
  end

  def self.rearrange_events(discussion)
    Event.where(discussion_id: discussion.id).update_all(parent_id: discussion.created_event.id, position: 0, depth: 1, child_count: 0)
    Event.where(discussion_id: discussion.id).order(:sequence_id).each(&:set_parent_and_depth!)
    parent_ids = Event.where(discussion_id: discussion.id).pluck(:parent_id).sort.uniq
    Event.where(id: parent_ids).each do |parent_event|
      parent_event.reorder
      parent_event.update_child_count
    end
  end

end
