require 'json'

class Fact < Linkbot::Plugin

  register :regex => Regexp.new('!fact(?: (\d+))?')
  help '!fact <fact number> - get a random fact from mental floss or by fact number'
  description 'Retrieve a random fact from mental floss'

  def self.on_message(message, match, config)
    factnumber = match[0]

    if factnumber.nil?
      factnumber = rand(2001)
    elsif factnumber.to_i > 2000
      factnumber = rand(2001)
    else
      factnumber = factnumber.to_i
    end

    mentalfloss = "http://mentalfloss.com/amazingfactgenerator/load-fact.php?id=#{factnumber}"
    doc = JSON.parse(open(mentalfloss).read)

    outputStr = doc["post_content"]
        
    if outputStr.empty?
      "The fact is no facts came back..."
    else
      outputStr
    end
  end

end
