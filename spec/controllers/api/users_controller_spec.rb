require 'rails_helper'
describe API::UsersController do

  let(:user) { create :user }
  let(:another_user) { create :user }
  let(:user_params) { { name: "new name", email: "new@email.com" } }

  before do
    sign_in user
  end

  describe 'update_profile' do
    context 'success' do
      it "updates a users profile" do
        post :update_profile, user: user_params, format: :json
        expect(response).to be_success
        expect(user.reload.email).to eq user_params[:email]
        json = JSON.parse(response.body)
        user_emails = json['users'].map { |v| v['email'] }
        expect(user_emails).to include user_params[:email]
      end

      it "changes a users password" do
        old_password = user.encrypted_password
        post :update_profile, user: { current_password: 'complex_password', password: 'new_password', password_confirmation: 'new_password'}, format: :json
        expect(response).to be_success
        expect(user.reload.encrypted_password).not_to eq old_password
        json = JSON.parse(response.body)
        user_emails = json['users'].map { |v| v['email'] }
        expect(user_emails).to include user.email
      end
    end

    context 'failures' do
      it "responds with an error when there are unpermitted params" do
        user_params[:dontmindme] = 'wild wooly byte virus'
        put :update_profile, user: user_params, format: :json
        expect(JSON.parse(response.body)['exception']).to eq 'ActionController::UnpermittedParameters'
      end

      it 'does not allow a change if current password does not match' do
        old_password = user.encrypted_password
        post :update_profile, user: { current_password: 'not right', password: 'new_password', password_confirmation: 'errwhoops'}, format: :json
        expect(response).to_not be_success
        expect(user.reload.encrypted_password).to eq old_password
      end

      it 'does not allow a change if passwords dont match' do
        old_password = user.encrypted_password
        post :update_profile, user: { password: 'new_password', password_confirmation: 'errwhoops'}, format: :json
        expect(response).to_not be_success
        expect(user.reload.encrypted_password).to eq old_password
      end
    end
  end

  describe 'deactivate' do
    context 'success' do
      it "deactivates the users account" do
        post :deactivate, user: {deactivation_response: '' }, format: :json
        expect(response).to be_success
        json = JSON.parse(response.body)
        user_emails = json['users'].map { |v| v['email'] }
        expect(user_emails).to include user.email
        expect(user.reload.deactivated_at).to be_present
        expect(UserDeactivationResponse.last).to be_blank
      end

      it 'can record a deactivation response' do
        post :deactivate, user: { deactivation_response: '(╯°□°)╯︵ ┻━┻'}, format: :json
        deactivation_response = UserDeactivationResponse.last
        expect(deactivation_response.body).to eq '(╯°□°)╯︵ ┻━┻'
        expect(deactivation_response.user).to eq user
      end
    end
  end

end
