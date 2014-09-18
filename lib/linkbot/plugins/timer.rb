class Timer < Linkbot::Plugin

  register :regex => /!timer (\d+)\s?(.*)/i
  help "!timer <seconds> [message] - set a timer, optionally saying something."
  description 'Set a timer for a reminder'

  @active = 0

  def self.on_message(message, matches, config)
    if @active >= 5
      "There are currently 5 timers running. Wait your turn."
    elsif matches[0].to_i > 9000
      "Timers cannot be longer than 15 minutes"
    else
      @active = @active + 1
      seconds = matches[0].to_i
      message = matches[1].length > 0 ? matches[1] : "NURRRRRR ALARM NURRRRR"
      sleep(seconds)
      @active = @active - 1
      message
    end
  end


end
