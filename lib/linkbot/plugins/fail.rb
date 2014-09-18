require 'open-uri'
require 'hpricot'

class Fail < Linkbot::Plugin
  include HTTParty
    
  register :regex => /^fail( .+)?/i
  description 'On failure, random image from failblog'

  global_config "webhook", :type => :string, :name => "Web Hook"

  def self.on_message(message, matches, config)

    doc = Hpricot(open("http://www.failpictures.com").read)
    img = "http://www.failpictures.com/" + doc.search("img[@alt='following next photo']").first.attributes['src']
    
    if config["webhook"]
      get("#{config["webhook"]}")
    end
    
    img
  end

end
