require 'rails_helper'
describe API::MembershipsController do

  let(:user) { create :user }
  let(:another_user) { create :user }
  let(:user_named_biff) { create :user, name: "Biff Bones" }
  let(:user_named_bang) { create :user, name: "Bang Whamfist" }
  let(:alien_named_biff) { create :user, name: "Biff Beef", email: 'beef@biff.com' }
  let(:alien_named_bang) { create :user, name: 'Bang Beefthrong' }
  let(:pending_named_barb) { create :user, name: 'Barb Backspace' }

  let(:group) { create :group }
  let(:another_group) { create :group }
  let(:subgroup) { create :group, parent: group }
  let(:discussion) { create :discussion, group: group }
  let(:comment_params) {{
    body: 'Yo dawg those kittens be trippin for some dippin',
    discussion_id: discussion.id
  }}

  before do
    group.add_admin! user
    group.add_member! user_named_biff
    group.add_member! user_named_bang
    another_group.add_member! user
    another_group.add_member! alien_named_bang
    another_group.add_member! alien_named_biff
    subgroup.add_member! user
    group.memberships.create!(user: pending_named_barb, accepted_at: nil)
    sign_in user
  end

  describe 'create' do
    it 'sets the membership volume' do
      new_group = FactoryBot.create(:group)
      user.update_attribute(:default_membership_volume, 'quiet')
      membership = Membership.create!(user: user, group: new_group)
      expect(membership.volume).to eq 'quiet'
    end
  end

  describe 'update' do
    it 'updates membership title, user titles, and broadcasts author to group' do
      m = group.membership_for(user_named_biff)
      post :update, params: { id: m.id, membership: {title: 'dr' } }
      expect(response.status).to eq 200
      expect(m.reload.title).to eq 'dr'
      expect(user_named_biff.reload.experiences['titles'][m.group_id.to_s]).to eq 'dr'
    end
  end

  describe 'resend' do
    let(:group) { create :group }
    let(:discussion) { create :discussion }
    let(:poll) { create :poll }
    let(:user) { create :user }
    let(:group_invite) { create :membership, accepted_at: nil, inviter: user, group: group }

    before { sign_in user }

    it 'can resend a group invite' do
      expect { post :resend, params: { id: group_invite.id } }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(response.status).to eq 200
    end

    it 'does not send if not the inviter' do
      group_invite.update(inviter: create(:user))
      expect { post :resend, params: { id: group_invite.id } }.to_not change { ActionMailer::Base.deliveries.count }
      expect(response.status).to eq 403
    end

    it 'does not send if accepted' do
      group_invite.update(accepted_at: 1.day.ago)
      expect { post :resend, params: { id: group_invite.id } }.to_not change { ActionMailer::Base.deliveries.count }
      expect(response.status).to eq 403
    end
  end

  describe 'set_volume' do
    before do
      @discussion = FactoryBot.create(:discussion, group: group)
      @another_discussion = FactoryBot.create(:discussion, group: group)
      @membership = group.membership_for(user)
      @membership.set_volume! 'quiet'
      @second_membership = subgroup.membership_for(user)
      @second_membership.set_volume! 'quiet'
      @reader = DiscussionReader.for(discussion: @discussion, user: user)
      @reader.save!
      @reader.set_volume! 'normal'
      @second_reader = DiscussionReader.for(discussion: @another_discussion, user: user)
      @second_reader.save!
      @second_reader.set_volume! 'normal'
    end
    it 'updates the discussion readers' do
      put :set_volume, params: { id: @membership.id, volume: 'loud' }
      @reader.reload
      @second_reader.reload
      expect(@reader.computed_volume).to eq 'loud'
      expect(@second_reader.computed_volume).to eq 'loud'
    end
    context 'when apply to all is true' do
      it 'updates the volume for all memberships' do
        put :set_volume, params: { id: @membership.id, volume: 'loud', apply_to_all: true }
        @membership.reload
        @second_membership.reload
        expect(@membership.volume).to eq 'loud'
        expect(@second_membership.volume).to eq 'loud'
      end
    end
    context 'when apply to all is false' do
      it 'updates the volume for a single membership' do
        put :set_volume, params: { id: @membership.id, volume: 'loud'}
        @membership.reload
        @second_membership.reload
        expect(@membership.volume).to eq 'loud'
        expect(@second_membership.volume).not_to eq 'loud'
      end
    end
  end

  describe 'search via index' do
    let(:emrob_jones) { create :user, name: 'emrob jones' }
    let(:rob_jones) { create :user, name: 'rob jones' }
    let(:jim_robinson) { create :user, name: 'jim robinson' }
    let(:jim_emrob) { create :user, name: 'jim emrob' }
    let(:rob_othergroup) { create :user, name: 'rob othergroup' }

    context 'success' do
      before do
        emrob_jones
        rob_jones
        jim_robinson
        jim_emrob
        group.add_member!(emrob_jones)
        group.add_member!(rob_jones)
        group.add_member!(jim_robinson)
        group.add_member!(jim_emrob)
        another_group.add_member!(rob_othergroup)
      end
      it 'returns users filtered by query' do
        get :index, params: { group_id: group.id, q: 'rob' }, format: :json

        user_ids = JSON.parse(response.body)['users'].map{|c| c['id']}

        expect(user_ids).to_not include emrob_jones.id
        expect(user_ids).to include rob_jones.id
        expect(user_ids).to include jim_robinson.id
        expect(user_ids).to_not include jim_emrob.id
        expect(user_ids).to_not include rob_othergroup.id
      end
    end

    context 'failure' do
      it 'does not allow access to an unauthorized group' do
        cant_see_me = create :group
        get :index, params: { group_id: cant_see_me.id }
        expect(JSON.parse(response.body)['exception']).to include 'CanCan::AccessDenied'
      end
    end
  end

  describe 'index' do
    context 'success' do
      it 'returns users filtered by group' do
        get :index, params: { group_id: group.id }, format: :json
        json = JSON.parse(response.body)
        expect(json.keys).to include *(%w[users memberships groups])
        users = json['users'].map { |c| c['id'] }
        groups = json['groups'].map { |g| g['id'] }
        expect(users).to include user_named_biff.id
        expect(users).to_not include alien_named_biff.id
        expect(users).to include pending_named_barb.id
        expect(groups).to include group.id
      end

      # it 'returns pending users' do
      #   get :index, params: { group_id: group.id, pending: true }, format: :json
      #   json = JSON.parse(response.body)
      #
      #   user_ids = json['users'].map { |c| c['id'] }
      #   groups = json['groups'].map { |g| g['id'] }
      #   expect(user_ids).to include pending_named_barb.id
      #   expect(groups).to include group.id
      # end

      context 'logged out' do
        before { @controller.stub(:current_user).and_return(LoggedOutUser.new) }
        let(:private_group) { create(:group, is_visible_to_public: false) }

        it 'returns no users for a public group' do
          group.update(group_privacy: 'open')
          get :index, params: { group_id: group.id }, format: :json
          json = JSON.parse(response.body)
          expect(json['memberships'].length).to eq 0
        end

        it 'responds with unauthorized for private groups' do
          get :index, params: { group_id: private_group.id }, format: :json
          expect(response.status).to eq 403
        end
      end
    end
  end

  describe 'for_user' do
    let(:public_group) { create :group, is_visible_to_public: true }
    let(:private_group) { create :group, is_visible_to_public: false }

    it 'returns visible groups for the given user' do
      public_group
      private_group.add_member! another_user
      group.add_member! another_user

      get :for_user, params: { user_id: another_user.id }
      json = JSON.parse(response.body)
      group_ids = json['groups'].map { |g| g['id'] }
      expect(group_ids).to include group.id
      expect(group_ids).to_not include public_group.id
      expect(group_ids).to_not include private_group.id
    end
  end


  describe 'save_experience' do

    it 'successfully saves an experience' do
      membership = create(:membership, user: user)
      post :save_experience, params: { id: membership.id, experience: :happiness }
      expect(response.status).to eq 200
      expect(membership.reload.experiences['happiness']).to eq true
    end

    it 'responds with forbidden when user is logged out' do
      membership = create(:membership)
      post :save_experience, params: { id: membership.id, experience: :happiness }
      expect(response.status).to eq 403
    end

    it 'responds with bad request when no experience is given' do
      membership = create(:membership)
      expect { post :save_experience }.to raise_error { ActionController::ParameterMissing }
    end
  end
end
