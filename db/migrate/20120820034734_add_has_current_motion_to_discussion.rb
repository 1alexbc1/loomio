class AddHasCurrentMotionToDiscussion < ActiveRecord::Migration
  class Discussion < ActiveRecord::Base
    has_many :motions
    def current_motion
      motion = motions.where("phase = 'voting'").last if motions
      if motion
        motion.open_close_motion
        motion if motion.voting?
      end
    end
  end

  def change
    add_column :discussions, :has_current_motion, :boolean, :default => false

    Discussion.reset_column_information
    Discussion.all.each do |discussion|
      if discussion.current_motion
        discussion.has_current_motion = true
        discussion.save!
      end
    end
  end
end
