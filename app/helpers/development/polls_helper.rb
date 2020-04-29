module Development::PollsHelper

  private

  def test_poll(stance_data: { red: 3, green: 1, blue: 2 })
    @test_proposal ||= FactoryGirl.create :poll,
      poll_type: 'poll',
      poll_option_names: ['red', 'green', 'blue'],
      discussion: test_discussion,
      stance_data: stance_data,
      author: patrick
  end

  def test_proposal(stance_data: { agree: 5, abstain: 3, disagree: 2, block: 1 })
    @test_proposal ||= FactoryGirl.create :poll,
      poll_type: 'proposal',
      poll_option_names: ['agree', 'disagree', 'abstain', 'block'],
      discussion: test_discussion,
      stance_data: stance_data,
      author: patrick
  end

  def test_agree
    @test_agree ||= FactoryGirl.create :stance,
      poll: test_proposal,
      reason: "I am agreeing!",
      participant: patrick,
      stance_choices_attributes: [{
        poll_option_id: test_proposal.poll_options.find_by(name: 'agree').id
      }]
  end

  def test_abstain
    @test_abstain ||= FactoryGirl.create :stance,
      poll: test_proposal,
      reason: "I am abstaining!",
      participant: emilio,
      stance_choices_attributes: [{
        poll_option_id: test_proposal.poll_options.find_by(name: 'abstain').id
      }]
  end

  def test_disagree
    @test_disagree ||= FactoryGirl.create :stance,
      poll: test_proposal,
      reason: "I am disagreeing!",
      participant: jennifer,
      stance_choices_attributes: [{
        poll_option_id: test_proposal.poll_options.find_by(name: 'disagree').id
      }]
  end

  def poll_email_info(poll: test_poll, recipient: patrick, utm: {})
    @info ||= PollEmailInfo.new(poll: poll, recipient: recipient, utm: utm)
  end
end
