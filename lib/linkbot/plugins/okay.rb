class Okay < Linkbot::Plugin

  register :regex => /okay\./i
  description 'Defeated okay.'

  def self.on_message(message, matches, config)
    "http://i.imgur.com/p7uaa.jpg"
  end

end
