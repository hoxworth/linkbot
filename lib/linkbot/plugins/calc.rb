require 'open-uri'
require 'cgi'

class Calc < Linkbot::Plugin

  register :regex => /!calc (.+)/i
  description "Calculator plugin"

  def self.on_message(message, matches, config)
    query = CGI.escape(matches[0])
    url = "https://encrypted.google.com/search?hl=en&q=#{query}"
    doc = Hpricot(open(url).read)

    begin
      answer = (doc/'h2').find {|x| x.attributes["class"] == 'r'}.html
    rescue NoMethodError
      return ["unable to calculate #{matches[0]}"]
    end

    #hipchat doesn't support <sup>
    answer.gsub! /<sup>/, '^'
    answer.gsub! /<\/sup>/, ''

    #we're not allowed HTML entities, so replace &#215; with x
    answer.gsub! /&#215;/, "\u00d7"

    [answer]
  end
end