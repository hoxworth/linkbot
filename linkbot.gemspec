lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'linkbot/version'

Gem::Specification.new do |s|
  s.name          = "linkbot"
  s.version       = Linkbot::VERSION
  s.authors       = ["Kenny Hoxworth", "Mark Olson", "Bill Mill", "Kafu Chau", "Jason Denney"]
  s.email         = ["hoxworth@gmail.com", "theothermarkolson@gmail.com", "billmill@gmail.com"]
  s.description   = "A Ruby chatbot written for simple plugin generation and management"
  s.homepage      = "http://github.com/markolson/linkbot"
  s.summary       = "Ruby chatbot"

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(spec)/})
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.license = 'MIT'

  s.add_runtime_dependency 'sanitize'
  s.add_runtime_dependency 'htmlentities'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'sqlite3'
  s.add_runtime_dependency 'hpricot'
  s.add_runtime_dependency 'twss'
  s.add_runtime_dependency 'httparty'
  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'twitter-stream'
  s.add_runtime_dependency 'eventmachine'
  s.add_runtime_dependency 'rack'
  s.add_runtime_dependency 'thin', '~>1.5.0'
  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'xmpp4r'
  s.add_runtime_dependency 'image_size'
  s.add_runtime_dependency 'octokit'
  s.add_runtime_dependency 'tzinfo'
  s.add_runtime_dependency 'twilio-ruby'
  s.add_runtime_dependency 'phonie'
  s.add_runtime_dependency 'aws-sdk'
  s.add_runtime_dependency 'hipchat'
  s.add_runtime_dependency 'chronic'
  s.add_runtime_dependency 'unidecode'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
end
