#!/usr/bin/env ruby

require 'rubygems'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/linkbot"

# External dependencies
require 'twitter/json_stream'
require 'sanitize'
require 'htmlentities'
require 'eventmachine'
require 'em-http-request'
require 'json'
require 'httparty'
require 'rack'
require 'thin'
require 'pp'
require 'test'

# Internal dependencies
require 'config'
require 'util'
require 'db'
require 'plugin'
require 'connector'

module Linkbot

  class Bot
    attr_accessor :connectors

    @connectors = nil

    def self.connectors=(connectors)
      @connectors = connectors
    end

    def self.connectors
      @connectors
    end

    def initialize(dev = false)
      Linkbot.db
      Linkbot::Config.load
      Linkbot::Plugin.collect
      Linkbot::Connector.collect unless dev
      Linkbot.load_users
      @connectors = []
      Linkbot::Bot.connectors = @connectors
    end

    def run
      EventMachine::run do

        Linkbot::Config["connectors"].each do |config|
          if Linkbot::Connector[config["type"]]
            @connectors << Linkbot::Connector[config["type"]].new(config)
          end
        end

        @connectors.each do |connector|
          connector.onmessage do |message,options|
            EventMachine::defer(proc {
              messages = Linkbot::Plugin.handle_message(message)
              # Check for broadcasts
              if message.connector.options["broadcast"]
                # Go through all of the connectors and send to all that accept broadcasts
                @connectors.each do |c|
                  if c.options["receive_broadcasts"]
                    begin
                      c.send_messages(messages)
                    rescue => e
                      puts "the #{c} connector threw an exception: #{e.inspect}"
                      puts e.backtrace.join("\n")
                    end
                  end
                end
              else
                message.connector.send_messages(messages,options)
              end
            })
          end
        end

        #every 15 seconds, run periodic plugins
        EventMachine.add_periodic_timer(15) do

          @connectors.each do |c|
            begin
              c.periodic
            rescue Exception => e
              puts "error in call to #{c}"
              puts e
            end
          end
        end

        # Make the bot accessible!
        Linkbot::Admin.set :bot, self
        run_admin app: Linkbot::Admin.new
      end
    end # End run

    def run_admin(opts = {})
      server = opts[:server] || 'thin'
      host   = opts[:host] || '0.0.0.0'
      port   = opts[:port] || '45679'
      app    = opts[:app]

      dispatch = Rack::Builder.app do
        map '/' do
          run app
        end
      end

      unless ['thin', 'hatetepe', 'goliath'].include? server
        raise "Need an EM webserver, but #{server} isn't"
      end

      Rack::Server.start({
           app: dispatch,
        server: server,
          Host: host,
          Port: port
      })
    end

  end
end


