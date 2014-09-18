class Blush < Linkbot::Plugin
  include HTTParty

  register :regex => /hedwig\+\+/
  description "Bashful owl"


  def self.on_message(message, matches, config)
    images = [
      'http://media0.giphy.com/media/FlHuACrCGXkc0/giphy.gif',
      'http://media2.giphy.com/media/jIhYzsS1FIs00/giphy.gif',
      'http://i50.tinypic.com/2qki4bd.jpg',
      'http://38.media.tumblr.com/307ba87d3a8faefe75a06557747d2dc9/tumblr_myhmtft11j1rwfctbo1_1280.gif',
      'http://31.media.tumblr.com/cf1cd6f7cfea8bf2de2c201a8b86bc06/tumblr_n3jw4kf3AE1smcbm7o1_500.gif'
    ]

    images.sample
  end

end
