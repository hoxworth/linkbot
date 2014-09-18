# encoding: UTF-8
require 'uri'

class Links < Linkbot::Plugin

  register :regex => Regexp.new('(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’]))')

  global_config "whitelist", :name => "URL Whitelist", :type => :array, :subtype => :string, :default => []

  def self.on_message(message, matches, config)
    url = matches[0]
    url = URI.decode(url)
    uri = URI.parse(url)

    if config.has_key? "whitelist"
      whitelist = config["whitelist"].map do |link|
        new_uri = URI.parse(link)
        Regexp.new("^#{new_uri.host}#{new_uri.path}")
      end
    end

    # First, make sure this is a HTTP or HTTPS scheme
    if uri.scheme.downcase == "http" || uri.scheme.downcase == "https"

      # Make sure this link has not been whitelisted
      if whitelist
        whitelist.each do |whitelist_regex|
          if whitelist_regex.match("#{uri.host}#{uri.path}")
            return ''
          end
        end
      end
      messages = []

      rows = Linkbot.db.execute("select username, dt from links, users where links.user_id=users.user_id and url = ?", url)
      if rows.empty?
        Linkbot::Plugin.plugins.each {|k,v|
          messages << v[:ptr].on_newlink(message, url).join("\n") if(v[:ptr].respond_to?(:on_newlink))
        }
        # Add the link to the dupe table
        Linkbot.db.execute("insert into links (user_id, dt, url) VALUES (?, ?, ?)",
                           message.user_id, Time.now.to_s, url)
      else
        Linkbot::Plugin.plugins.each {|k,v|
          messages << v[:ptr].on_dupe(message, url, rows[0][0], rows[0][1]) if(v[:ptr].respond_to?(:on_dupe))
        }
      end
      messages.join("\n")
    else
      ''
    end
  end

end
