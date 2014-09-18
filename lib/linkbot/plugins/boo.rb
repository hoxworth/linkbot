class Boo < Linkbot::Plugin
  include HTTParty
  
  register :regex => /^bo+\b/i
  description "Boo and get booed"

  global_config "webhook", :type => :string, :name => "Web Hook"

  def self.on_message(message, matches, config)
    get(config["webhook"]) if config["webhook"]
    "http://i.imgur.com/nx70H.jpg"
  end
end
