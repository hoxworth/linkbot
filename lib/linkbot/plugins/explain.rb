class Explain < Linkbot::Plugin
    register :regex => /!explain(?: (.+))?/i

    def self.on_message(message, matches, config)
      "http://explainshell.com/explain?cmd=#{CGI.escape(matches[0])}"
    end
end
