require 'spec_helper'

describe Discussion do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:group) }
  it { should validate_presence_of(:author) }
  it { should ensure_length_of(:title).
               is_at_most(150) }

  it "author must belong to group" do
    discussion = Discussion.new(group: Group.make!)
    discussion.author = User.make!
    discussion.should_not be_valid
  end

  it "group member can add comment" do
    user = User.make!
    discussion = create_discussion
    discussion.group.add_member! user
    comment = discussion.add_comment(user, "this is a test comment")
    discussion.comment_threads.should include(comment)
  end

  it "group non-member cannot add comment" do
    discussion = create_discussion
    comment = discussion.add_comment(User.make!, "this is a test comment")
    discussion.comment_threads.should_not include(comment)
  end

  it "can update discussion_activity" do
    discussion = create_discussion
    discussion.activity = 3
    discussion.update_activity
    discussion.activity.should == 4
  end

end
