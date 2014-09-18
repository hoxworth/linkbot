require 'json'

class Cats < Linkbot::Plugin

  register :regex=> /^!cats$/i
  help '!cats - show a random cat gif'
  description "Random cat antics"

  def self.on_message(message, matches, config)
    JSON.parse(open('http://catstreamer.herokuapp.com/cats.json').read)['catpic']
  end

end
