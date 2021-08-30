require "rails_helper"

describe "Events::Position" do
  let(:group) { FactoryBot.create :group }
  let(:discussion) { create :discussion, group: group }
  let(:comment1) { create :comment, discussion: discussion }
  let(:comment2) { create :comment, discussion: discussion }
  let(:comment3) { create :comment, discussion: discussion }

  before do
    discussion.create_missing_created_event!
  end

  it "gives events with a parent_id a pos sequence" do
    puts "created_event position #{discussion.created_event.position}, sequence_id: #{discussion.created_event.sequence_id}"
    e1 = Event.create!(kind: "new_comment", parent: discussion.created_event, discussion: discussion, eventable: comment1)
    puts "e1 position #{e1.position}, sequence_id: #{e1.sequence_id}"
    e2 = Event.create!(kind: "new_comment", parent: discussion.created_event, discussion: discussion, eventable: comment2)
    puts "e2 position #{e2.position}, sequence_id: #{e2.sequence_id}"
    e3 = Event.create!(kind: "new_comment", parent: discussion.created_event, discussion: discussion, eventable: comment3)
    puts "e3 position #{e3.position}, sequence_id: #{e3.sequence_id}"

    expect(e1.position).to eq 1
    expect(e1.position_key).to eq "00001"
    expect(e2.position).to eq 2
    expect(e2.position_key).to eq "00002"
    expect(e3.position).to eq 3
    expect(e3.position_key).to eq "00003"
  end

  describe 'depth' do
    let(:comment1) { create :comment, discussion: discussion }
    let(:comment2) { create :comment, discussion: discussion, parent: comment1 }
    let(:comment3) { create :comment, discussion: discussion, parent: comment2 }

    it "enforces max depth 2 " do
      e1 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment1)
      e2 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment2)
      e3 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment3)
      expect(e1.depth).to eq 1
      expect(e1.position_key).to eq "00001"
      expect(e2.depth).to eq 2
      expect(e2.position_key).to eq "00001-00001"
      expect(e3.depth).to eq 2
      expect(e3.position_key).to eq "00001-00002"
    end

    it "enforces max depth 1 " do
      discussion.update(max_depth: 1)
      e1 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment1)
      e2 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment2)
      e3 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment3)
      expect(e1.depth).to eq 1
      expect(e1.position_key).to eq "00001"
      expect(e2.depth).to eq 1
      expect(e2.position_key).to eq "00002"
      expect(e3.depth).to eq 1
      expect(e3.position_key).to eq "00003"
    end

    it "enforces max depth 3 " do
      discussion.update(max_depth: 3)
      e1 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment1)
      e2 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment2)
      e3 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment3)
      expect(e1.depth).to eq 1
      expect(e1.position_key).to eq "00001"
      expect(e2.depth).to eq 2
      expect(e2.position_key).to eq "00001-00001"
      expect(e3.depth).to eq 3
      expect(e3.position_key).to eq "00001-00001-00001"
    end
  end

  it "reorders if parent changes" do
    e1 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment1)
    e2 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment2)
    expect(e1.reload.position).to eq 1
    expect(e2.reload.position).to eq 2
  end

  it "removes position if discussion_id is dropped" do
    e1 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment1)
    e2 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment2)
    e3 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment3)
    expect(e1.position).to eq 1
    expect(e2.position).to eq 2
    expect(e3.position).to eq 3
    e2.update(discussion_id: nil, parent_id: nil)
    EventService.repair_thread(discussion.id)
    expect(e3.reload.position).to eq 2
    expect(e3.reload.position_key).to eq "00002"
  end

  it "handles destroy" do
    e1 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment1)
    e2 = Event.create!(kind: "new_comment", discussion: discussion, eventable: comment2)
    expect(e1.position).to eq 1
    expect(e2.position).to eq 2
    e1.destroy
    EventService.repair_thread(discussion.id)
    e2.reload
    expect(e2.position).to eq 1
  end
end
