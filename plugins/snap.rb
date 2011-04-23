class Snap < Linkbot::Plugin
    def self.on_message(user, message, matches, msg)
      snaps = [	"http://i52.tinypic.com/302melk.gif",
      		"http://www.youtube.com/watch?v=qL3TWooBGrI",
      		"http://i51.tinypic.com/2roj8k0.jpg",
      		"http://i3.photobucket.com/albums/y79/IJG/oh_snap.gif",
      		"http://webimages.stephen-wright.net/house-ohsnap.gif"
            ]
      [snaps[rand(snaps.length)]]
    end

    Linkbot::Plugin.register('snap', self,
      {
        :message => {:regex => /SNAP\!/, :handler => :on_message}
      }
    )
end