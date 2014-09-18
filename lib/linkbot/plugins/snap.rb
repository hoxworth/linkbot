class Snap < Linkbot::Plugin

  register :regex => /SNAP\!/
  global_config "images", :type => :array, :subtype => :string, :name => "OH SNAP! Images", :default => []
  description 'OH SNAP!'

  def self.on_message(message, matches, config)
    return config["images"][rand(config["images"].length)] if config["images"].length > 0
    ''
  end

end
