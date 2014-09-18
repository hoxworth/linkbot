require 'sinatra'
require 'aws-sdk'
require 'config'
require 'pp'
require 'hipchat'


module Linkbot
  class Admin < Sinatra::Base
    @@s3 = AWS::S3.new
    @@bucket = @@s3.buckets['com.twilio.dev.roles/messaging-hedwig']

    get '/' do
      rooms = []

      # Grab the hipchat rooms if we have them
      if Linkbot::Config["connectors"][0]
        client = HipChat::Client.new(Linkbot::Config["connectors"][0]["api_token"])
        rooms = client.rooms.map {|room| {:name => room.name, :xmpp => room.xmpp_jid.split("@")[0]}}
      end

      # all plugin names
      allplugins = Linkbot::Plugin.plugins

      # plugins with configuration options, including options
      configplugins = Linkbot::Plugin.global_config_options

      roomplugins = Linkbot::Plugin.room_config_options

      # get the plugin names that are configurable
      configpluginnames = Array.new()
      configplugins.keys.sort.each do |key|
        configpluginnames.push(key)
      end

      # get all plugin names
      plugins = Array.new()
      allplugins.keys.sort.each do |key|
        plugins.push(allplugins[key])
      end

      # dictionary storage for all configurable plugin fields for quick config
      # field lookups - iterate through all configurable plugins
      configoptions = Hash.new()
      configpluginnames.sort.each do |name|
        # array to hold all fields
        allconfigs = Array.new()
        configoptions[name] = allconfigs

        # for each plugin's configurable field, store it in its own array
        configplugins[name].each do |random|
          configurablefield = Array.new()
          # field descriptor, data type, and currently assigned name
          configurablefield.push(random[0])
          configurablefield.push(random[1][:type])
          configurablefield.push(random[1][:name])
          allconfigs.push(configurablefield)
        end

      end

      erb :base, :locals => {
        :plugins => plugins,
        :configpluginnames => configpluginnames,
        :configoptions => configoptions,
        :config => ::Linkbot::Config.settings,
        :rooms => rooms
      }
    end

    post '/' do
      begin
        config_data = JSON.parse(request.body.read)
      rescue JSON::JSONError
        return [500, {}, "Unable to parse JSON config"]
      end

      # Write config to file
      config_file = File.open("#{File.dirname(__FILE__)}/../../config.json", 'wb')
      config_file.write(JSON.pretty_generate(config_data))
      config_file.close

      # Only perform an S3 write if we are in the load balancer
      if Balancer.balancer
        begin
          # Delete old config object from S3
          config_obj = @@bucket.objects['config']
          config_obj.delete if config_obj.exists?

          # Push new obj to S3
          @@bucket.objects.create('config', JSON.pretty_generate(config_data))
        rescue Exception => e
          puts e.message
        end
      end

      # Reload the config
      Linkbot::Config.reload(settings.bot)

      [200, {}, "New config saved and loaded"]
    end

  end
end
