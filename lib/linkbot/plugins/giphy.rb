require 'open-uri'

class Giphy < Linkbot::Plugin

  register :regex => /!giphy(?: (.+))?/i
  help '!giphy [search term] - return an animated gif from giphy'
  description 'Produce an animated gif from giphy'

  create_log(:images)

  def self.on_message(message, matches, config)
    searchterm = matches[0]
    if searchterm.nil?
      searchterm = message_history(message)[0]['body']
    end

    gifs = []

    begin
      # Give giphy 5 seconds to respond (and for us to parse it!)
      Timeout::timeout(2) do
        searchurl = "http://api.giphy.com/v1/gifs/search?q=#{URI.encode(searchterm)}&api_key=dc6zaTOxFJmzC"
        gifs = JSON.parse(open(searchurl).read)["data"].map do |gif|
          gif["images"]["original"]["url"]
        end
      end
    rescue Timeout::Error
      return "Giphy is slow! No gifs for you."
    end

    return "No gifs found. Lame." if gifs.empty?

    gifs.sample
  end

end
