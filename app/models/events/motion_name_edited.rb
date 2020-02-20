class Events::MotionNameEdited < Event
  def self.publish!(motion, editor)
    create(kind: "motion_name_edited",
           eventable: motion,
           user: editor).tap { |e| Loomio::EventBus.broadcast('motion_name_edited_event', e) }
  end

  def group_key
    motion.group.key
  end

  def motion
    eventable
  end
end
