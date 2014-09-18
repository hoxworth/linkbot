class Morse < Linkbot::Plugin

  register :regex => /\A[\s\|\?\/\.-]+\s[\s\|\?\/\.-]+\z/i
  description 'Convert your message to morse code so you can talk to a ho-o-o-orse'

  def self.on_message(message, matches, config)
    morse_map = {
      '.-'   => 'A', '-...' => 'B', '-.-.' => 'C', '-..'  => 'D', '.'    => 'E',
      '..-.' => 'F', '--.'  => 'G', '....' => 'H', '..'   => 'I', '.---' => 'J',
      '-.-'  => 'K', '.-..' => 'L', '--'   => 'M', '-.'   => 'N', '---'  => 'O',
      '.--.' => 'P', '--.-' => 'Q', '.-.'  => 'R', '...'  => 'S', '-'    => 'T',
      '..-'  => 'U', '...-' => 'V', '.--'  => 'W', '-..-' => 'X', '-.--' => 'Y',
      '--..' => 'Z', '/'    => ' ', '|'    => ' '
    }

    translation = message.body.split(' ').map {|code| morse_map.fetch(code) {'?'} }.join
    "Mo-o-o-o-orse: #{translation}"
  end

end

