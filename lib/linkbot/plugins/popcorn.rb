class Popcorn < Linkbot::Plugin

    register :regex => /!popcorn/
    help '!popcorn - Everyone loves popcorn'
    description 'Random popcorn image'

    global_config "images", :type => :array, :subtype => :string, :name => "Popcorn Images", :default => []

    def self.on_message(message, matches, config)
      return config["images"][rand(config["images"].length)] if config["images"].length > 0
      ''
    end

end
