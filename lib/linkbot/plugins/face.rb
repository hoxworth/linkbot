class Face < Linkbot::Plugin

    register :regex => Regexp.new('/face')

    def self.on_message(message, matches, config)
      "http://i.imgur.com/ZbfvQ.gif"
    end

end
