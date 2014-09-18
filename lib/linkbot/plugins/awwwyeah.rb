class Awwyeah < Linkbot::Plugin
    register :regex => /a+w+ y+e+a+h+/i
    description "Aww yeah!"

    def self.on_message(message, matches, config)
      "http://i.imgur.com/Y3Q0Z.png"
    end
end
