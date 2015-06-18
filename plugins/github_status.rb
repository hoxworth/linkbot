require 'json'
require 'open-uri'
require 'active_support/time'

class Hubstat < Linkbot::Plugin
  @@config = Linkbot::Config["plugins"]["hubstat"]
  handlers = {
   :message => { :regex => /\A!hubstat/, :handler => :on_message, :help => :help },
  }
  if @@config && @@config['room']
    @@room = @@config['room']
    handlers[:periodic] = {:handler => :periodic}
  end

  Linkbot::Plugin.register('hubstat', self, handlers)

  if Linkbot.db.table_info('hubstatus').empty?
    Linkbot.db.execute('CREATE TABLE hubstatus (dt TEXT)');
  end

  def self.help
    '!hubstat - see whether your trouble with GitHub is just you'
  end

  def self.status_text(response)
    statuses = {
      "good" => "✅",
      "minor" => "⚠️",
      "major" => "🔴"
    }
    how_are_things = statuses.fetch(response['status'], '¯\_(ツ)_/¯')

    message_time = Time.parse(response["created_on"])
    timestr = message_time.in_time_zone("EST").strftime("%b %d %H:%m EST")

    "#{how_are_things} As of #{timestr}, GitHub is reporting: #{response["body"]}\nhttps://status.github.com/"
  end

  def self.periodic
    messages = []
    #by default, post the message if it's within the last day
    last_pulled = Time.now.utc - 60*60*24

    rows = Linkbot.db.execute("select dt from hubstatus")
    last_pulled = Time.parse(rows[0][0]) if !rows.empty? && rows[0][0]

    response = self.get_status

    #don't print the message if time exists and is newer than the message
    status_time = Time.parse(response["created_on"])
    if last_pulled && last_pulled < status_time
      messages << self.status_text(response)
    end

    Linkbot.db.execute("delete from hubstatus")
    Linkbot.db.execute("insert into hubstatus (dt) VALUES (?)", status_time.to_s)
    {:messages => messages, :options => { :room => @@room } }
  end

  def self.on_message(message, matches)
    response = self.get_status
    self.status_text(response)
  end

  def self.get_status
    JSON.parse(open('https://status.github.com/api/last-message.json').read)
  end
end
