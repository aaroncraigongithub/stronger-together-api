# frozen_string_literal:true
class PusherAlertWorker
  include Sidekiq::Worker

  def perform(alert_id)
    @alert = Alert.find alert_id

    @alert.user.friends.each do |friend|
      push friend.uuid
    end
  end

  protected

  def message
    @message ||=
      "#{@alert.user.name} needs your help.  Please call immediately."
  end

  # rubocop: disable Metrics/MethodLength
  def payload
    @payload ||= {
      message: message,
      apns: {
        aps: {
          alert: {
            body: message
          }
        }
      },
      fcm: {
        notification: {
          title: 'Stronger Together',
          body:  message
        }
      }
    }
  end
  # rubocop: enable Metrics/MethodLength

  def push(friend_id)
    Pusher.trigger(friend_id, 'alert', payload)
  end
end
