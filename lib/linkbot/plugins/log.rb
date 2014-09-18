class MessageLog < Linkbot::Plugin

  register
  hidden true

  def self.on_message(message, matches, config)
    log(:global, message)
    log(message[:options][:room], message) if message[:options][:room]
    log(message[:options][:user], message) if message[:options][:user]
    ""
  end
end
