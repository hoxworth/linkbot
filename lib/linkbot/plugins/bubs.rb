# encoding: utf-8

class Bubs < Linkbot::Plugin

  register :regex => /!bubs (.*)/
  description "See your text, in bubbles!"

  def self.on_message(message, matches, config)
    matches[0].tr('A-Za-z1-90', 'Ⓐ-Ⓩⓐ-ⓩ①-⑨⓪')
  end

end
