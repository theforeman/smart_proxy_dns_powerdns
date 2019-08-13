require File.expand_path('../lib/smart_proxy_dns_powerdns/dns_powerdns_version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'smart_proxy_dns_powerdns'
  s.version     = Proxy::Dns::Powerdns::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['Ewoud Kohl van Wijngaarden']
  s.email       = ['ewoud@kohlvanwijngaarden.nl']
  s.homepage    = 'https://github.com/theforeman/smart_proxy_dns_powerdns'

  s.summary     = "PowerDNS DNS provider plugin for Foreman's smart proxy"
  s.description = "PowerDNS DNS provider plugin for Foreman's smart proxy"

  s.files       = Dir['{config,lib,bundler.d}/**/*'] + ['README.md', 'LICENSE']
  s.test_files  = Dir['test/**/*']

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
end
