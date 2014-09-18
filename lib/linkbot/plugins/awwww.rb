require 'json'

class Awwww < Linkbot::Plugin

    register :regex => /^a+w+$/
    description "Random cute little animals and babies and all things happy"

    def self.on_message(message, matches, config)
      reddit = "http://www.reddit.com/r/aww.json"
      doc = JSON.parse(open(reddit).read)
      url = doc["data"]["children"][rand(doc["data"]["children"].length)]["data"]["url"]
      
      # Check if it's an imgur link without an image extension
      if url =~ /http:\/\/(www\.)?imgur\.com/ && !['jpg','png','gif'].include?(url.split('.').last)
        url += ".jpg"

        if ::Util.wallpaper?(url)
          url = [url, "(dealwithit) WALLPAPER WALLPAPER WALLPAPER (dealwithit)"]
        end
      end
      
      url
    end

end
