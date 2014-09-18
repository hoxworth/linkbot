require 'rubygems'
require 'sqlite3'

module Linkbot
  class Config
    @@settings = {}

    def self.settings
      @@settings
    end

    def self.[](x)
      @@settings[x]
    end

    def self.load
      begin
        @@settings = JSON.parse(open(File.join(File.dirname(__FILE__), "../../config.json")).read)
        @@settings["disabled_plugins"] ||= []

      rescue Errno::ENOENT
        puts "You must have a config.json file defined"
        exit(1)
      end
    end

    def self.reload(bot)
      old = settings
      self.load
      new = settings

      # Reconnect if connection config has changed
      unless old['connectors'].eql? new['connectors']
        puts "Connection configuration has changed, reconnecting..."
        Linkbot::Config.reconnect(bot)
      end

      # Join/Leave rooms if room presence has changed
      if old['rooms'].keys.count != new['rooms'].keys.count
        leave = old['rooms'].keys - new['rooms'].keys
        join  = new['rooms'].keys - old['rooms'].keys

        settings['connectors'].each do |conn|
          bot.connectors.select { |c|
            c.is_a?(Linkbot::Connector[conn['type']])
          }.map!{ |connector|
            leave.each {|rm| connector.leave(rm)}
            join.each {|rm| connector.join(rm, {})}
          }
        end
      end
    end # End reload

    def self.reconnect(bot)
      bot.connectors.each do |connector|
        connector.disconnect
        conn = settings['connectors'].first
        begin
          connector.reload_config(conn)
          connector.listen
        rescue Jabber::ClientAuthenticationFailure
          sleep_time = 1

          while(true) do
            begin
              puts "Failed to authenticate with Jabber service, sleeping for #{sleep_time}"
              sleep(sleep_time)
              connector.listen
            rescue Jabber::ClientAuthenticationFailure
              sleep_time = sleep_time * 2
            end
          end
        end
      end
    end

  end
end
