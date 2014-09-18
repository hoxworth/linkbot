class Qwantz < Linkbot::Plugin

  register :regex => /!qwantz/
  help '!qwantz - DINOSAUR COMICS'
  description 'Random dinosaur comic'
  
  def self.on_message(message, matches, config)
      doc = Hpricot(open('http://qwantz.com/index.php'))
      link = doc.search("div.randomquote a")[1]
      doc = Hpricot(open(link['href']))
      img = doc.search('img.comic')
      [link.inner_html.strip, img.first['src']]
  end

end
