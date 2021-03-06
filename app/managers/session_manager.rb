# frozen_string_literal: true
class SessionManager
  class SessionManager::InvalidLogin < StandardError; end

  def self.create(email, password)
    user = User.where('LOWER(email) = ?', email.downcase).first
    raise SessionManager::InvalidLogin if user.nil?
    raise SessionManager::InvalidLogin unless user.authenticate(password)

    user.token = SecureRandom.hex
    user.save!

    user
  end
end
