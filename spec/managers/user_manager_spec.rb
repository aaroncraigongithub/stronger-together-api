# frozen_string_literal:true
require 'rails_helper'

RSpec.describe UserManager do
  describe '#create' do
    let(:email)    { Faker::Internet.email }
    let(:password) { Faker::Lorem.characters(10) }
    let(:user)     { User.find_by(email: email) }

    context 'given a new email' do
      before do
        expect(
          described_class.create(email: email, password: password)
        ).to eq user.confirm_token
      end

      it 'creates the user' do
        expect(user).not_to be nil
      end

      it 'stores the token' do
        expect(user.confirm_token).not_to be nil
      end

      it 'queues a mail worker' do
        expect(ConfirmUserMailWorker.jobs.size).to eq 1
      end
    end

    context 'given an existing email' do
      let(:email) { create(:user).email }

      it 'throws an error' do
        expect{
          described_class.create(email: email, password: password)
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe '#confirm' do
    let(:user)  { create(:user) }
    let(:token) { user.confirm_token }

    context 'given a valid token' do
      before do
        described_class.confirm token
      end

      it 'confirms the user' do
        expect(user.reload.confirmed_at).not_to be nil
      end
    end

    context 'given an invalid token' do
      let(:token) { SecureRandom.hex }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          described_class.confirm token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'given a used token' do
      let(:user) { create(:confirmed_user) }

      it 'raises an UserManager::TokenAlreadyUsed error' do
        expect {
          described_class.confirm token
        }.to raise_error(UserManager::TokenAlreadyUsed)
      end
    end
  end

  describe '#invite_friends' do
    let(:emails) { [Faker::Internet.email] }
    let(:user)   { create(:confirmed_user) }

    context 'a confirmed user' do
      before do
        described_class.invite_friends user.id, emails
      end

      it 'queues the email worker' do
        expect(InviteFriendMailWorker.jobs.size).to eq 1
      end

      it 'queues the right params' do
        expect(InviteFriendMailWorker.jobs.first['args'])
          .to eq [user.id, emails.first]
      end
    end

    context 'an unconfirmed user' do
      let(:user) { create(:user) }

      it 'raises a UserManager::ConfirmedUserRequired error' do
        expect {
          described_class.invite_friends user.id, emails
        }.to raise_error(UserManager::ConfirmedUserRequired)
      end
    end

    context 'more than 20 emails' do
      let(:emails) { Array.new 21, Faker::Internet.email }

      it 'raises a UserManager::EmailLimitReached error' do
        expect {
          described_class.invite_friends user.id, emails
        }.to raise_error(UserManager::EmailLimitReached)
      end
    end
  end
end