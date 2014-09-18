class Google < Linkbot::Plugin

  register :regex => /!google (.+)/
  help '!google <term>: return the first google result'
  description 'Search google'

  def self.on_message(message, matches, config)
    searchterm = URI.encode(matches[0])
    doc = Hpricot(open("https://encrypted.google.com/search?q=#{searchterm}").read)
    doc.search("h3[@class=r] a")[0].to_s.match(/q=(.*?)&/)[1]
  end

end
