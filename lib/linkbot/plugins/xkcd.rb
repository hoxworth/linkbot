require 'open-uri'

class XKCD < Linkbot::Plugin

  register :regex => /!(relevant)?xkcd ?(.+)?/i
  help '!xkcd [search] - Relevant xkcd comic for a search or the last message'
  description 'Find a relevant xkcd comic for a search or the last message'

  def self.on_message(message, matches, config)
    search = matches[1]
    if search.nil?
      search = message_history(message)[1]['body']
    end

    xkcds = []
    error = "Sorry, xkcdbot encountered an error\n"\
            "http://www.explainxkcd.com/wiki/images/3/38/error_code.png"

    begin
      # Give the api 5 seconds to respond (and for us to parse it!)
      Timeout::timeout(5) do
        searchurl = "http://relevantxkcd.appspot.com/process?action=xkcd&query=#{URI.encode(search)}"
        lines = open(searchurl).read.split("\n")
        xkcds = lines[2..-1].map{|line| line.split(" ")}
      end
    rescue
      return error
    end

    return error if xkcds.empty?

    path = xkcds[0][1]
    "http://explainxkcd.com%s" % path
  end
end
