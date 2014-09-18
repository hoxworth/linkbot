require 'rubygems'
require 'pp'
require_relative 'db'

class MessageType
  MESSAGE       = :message
  DIRECTMESSAGE = :"direct-message"
  STARRED       = :starred
  UNSTARRED     = :unstarred
end

#The interface message object between Linkbot::Plugin and the plugins.
#New axiom: the plugins know nothing about the service they're using!
Message = Struct.new(:body, :user_id, :user_name, :connector, :type, :options)

Response = Struct.new(:message, :options)

module Linkbot
  class Plugin
    @@plugins = {}
    @@message_logs = {}
    @@message_logs[:global] = []

    @@global_config_options = {}
    @@room_config_options = {}

    def self.handle_message(message)
      @@message_logs[:global] << message

      # Check for a room-wide message
      if message[:options][:room]
        @@message_logs[message[:options][:room]] ||= []
        @@message_logs[message[:options][:room]] << message
      end

      # Check for a user-specific message
      if message[:options][:user]
         @@message_logs[message[:options][:user]] ||= []
         @@message_logs[message[:options][:user]] << message
      end

      final_message = []

      Linkbot::Plugin.plugins.each {|k,v|
        if !::Linkbot::Config["disabled_plugins"].include?(v[:ptr].name) &&
           v[:ptr].has_permission?(message) &&
           v[:handlers][message.type] &&
           v[:handlers][message.type][:handler]

          if (v[:handlers][message.type][:regex] && v[:handlers][message.type][:regex].match(message.body)) || v[:handlers][message.type][:regex].nil?

            matches = v[:handlers][message.type][:regex] ? v[:handlers][message.type][:regex].match(message.body).to_a.drop(1) : nil
            puts "#{k} processing message type #{message.type}"
            begin
              # Generate the config
              global_config = Linkbot::Config["plugins"][v[:ptr].name] || {}
              room_config = {}
              if message[:options][:room]
                if ::Linkbot::Config["rooms"][message[:options][:room]] &&
                   ::Linkbot::Config["rooms"][message[:options][:room]]["config"] &&
                   ::Linkbot::Config["rooms"][message[:options][:room]]["config"][v[:ptr].name]
                  room_config =  ::Linkbot::Config["rooms"][message[:options][:room]]["config"][v[:ptr].name]
                end
              end

              config = global_config.merge(room_config)

              end_msg = v[:ptr].send(v[:handlers][message.type][:handler], message, matches, config)

              unless end_msg.empty?
                if end_msg.is_a? Array
                  final_message.concat(end_msg)
                else
                  final_message << end_msg
                end
              end
            rescue => e
              end_msg = "the #{k} plugin threw an exception: #{e.inspect}"
              puts e.inspect
              puts e.backtrace.join("\n")
            end
          end
        end
      }
      puts "returning msgs from plugins:"
      pp final_message
      final_message
    end

    def self.handle_periodic
      final_messages = []

      Linkbot::Plugin.plugins.each {|k,v|
        if v[:handlers][:periodic] && v[:handlers][:periodic][:handler]

          puts "#{k} processing periodic message"
          begin
            #messages should be a hash {:messages => [<message:string>],
            #                           :options => {"room": <room:string>}
            #                          }
            messages = v[:ptr].send(v[:handlers][:periodic][:handler])

            unless messages[:messages].empty?
              final_messages << messages
            end
          rescue Exception => e
            final_messages << "the #{k} plugin threw an exception: #{e.inspect}"
            puts e.inspect
            puts e.backtrace.join("\n")
          end
        end
      }

      if final_messages.length
        puts "returning msgs from periodic plugins:"
        pp final_messages
      end
      final_messages
    end

    def self.has_permission?(message)
      if message[:options][:room]
        if ::Linkbot::Config["rooms"][message[:options][:room]]
          room_permissions = ::Linkbot::Config["rooms"][message[:options][:room]]

          if room_permissions["whitelist"]
            return room_permissions["whitelist"].include?(self.name)
          elsif room_permissions["blacklist"]
            return !room_permissions["blacklist"].include?(self.name)
          else
            return true
          end
        end
      end

      true
    end

    def self.message_history(message)
      if message[:options][:room]
        @@message_logs[message[:options][:room]]
      elsif message[:options][:user]
        @@message_logs[message[:options][:user]]
      else
        @@message_logs[:global]
      end
    end

    def self.create_log(log_name)
      @@message_logs[log_name] ||= []
    end

    def self.log(log_name, message)
      if @@message_logs[log_name].length >= 100
        @@message_logs[log_name].pop
      end
      @@message_logs[log_name].unshift(message)
    end

    def self.registered_methods
      @registered_methods ||= {}
      @registered_methods
    end

    def self.plugins; @@plugins; end;
    def self.global_config_options; @@global_config_options; end;
    def self.room_config_options; @@room_config_options; end;

    def self.collect
      Dir["#{File.dirname(__FILE__)}/plugins/*.rb"].each do |file|
        begin
          load file
        rescue Exception => e
          puts "unable to load plugin #{file}"
          puts e
        end
      end
    end

    def self.register_plugin(name, s, handlers)
      @@plugins[name] = {:ptr => s, :handlers => handlers}
    end

    def self.room_config(name, options = {})
      @room_config ||= {}
      @room_config[name] = options

      @@room_config_options[self.name] ||= {}
      @@room_config_options[self.name][name] = options
    end

    def self.global_config(name, options = {})
      @global_config ||= {}
      @global_config[name] = options

      @@global_config_options[self.name] ||= {}
      @@global_config_options[self.name][name] = options
    end

    def self.register(options = {})
      name = options[:name] || self.name

      handlers = {}
      message_handler = options[:handler] || :on_message
      handlers[:message] = {:regex => options[:regex], :handler => message_handler}

      if options.has_key? :periodic
        periodic_handler = options[:periodic][:handler] || :periodic
        handlers[:periodic] = { :handler => periodic_handler }
      end

      register_plugin(name, self, handlers)
    end

    def self.help(message = nil)
      @help = message if !message.nil?
      @help
    end

    def self.description(message = nil)
      @description = message if !message.nil?
      @description
    end

    def self.hidden(val = nil)
      @hidden = val if !val.nil?
      @hidden
    end

  end

end

