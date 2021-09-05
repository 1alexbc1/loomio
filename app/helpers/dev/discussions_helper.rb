module Dev::DiscussionsHelper
  include Dev::PollsHelper

  private

  def create_discussion_with_nested_comments
    group = create_group_with_members
    group.reload
    discussion    = saved fake_discussion(group: group)
    DiscussionService.create(discussion: discussion, actor: group.admins.first)

    BaseMailer.skip do
      15.times do
        parent_author = fake_user
        group.add_member! parent_author
        parent = fake_comment(discussion: discussion)
        CommentService.create(comment: parent, actor: parent_author)

        (0..3).to_a.sample.times do
          reply_author = fake_user
          group.add_member! reply_author
          reply = fake_comment(discussion: discussion, parent: parent)
          CommentService.create(comment: reply, actor: reply_author)
        end
      end
    end

    discussion.reload
    EventService.repair_thread(discussion.id)
    discussion.reload
  end

  def create_discussion_with_sampled_comments
    group = create_group_with_members

    discussion = saved fake_discussion(group: group)
    DiscussionService.create(discussion: discussion, actor: group.admins.first)
    discussion.update(max_depth: 3)

    BaseMailer.skip do
      5.times do
        group.add_member! saved(fake_user)
      end

      10.times do
        CommentService.create(comment: fake_comment(discussion: discussion), actor: group.members.sample)
      end
      comments = discussion.reload.comments

      10.times do
        CommentService.create(comment: fake_comment(discussion: discussion, parent: comments.sample), actor: group.members.sample)
      end

      comments = discussion.reload.comments

      10.times do
        CommentService.create(comment: fake_comment(discussion: discussion, parent: comments.sample), actor: group.members.sample)
      end
    end

    discussion.reload
    EventService.repair_thread(discussion.id)
    discussion.reload
    discussion
  end
end
