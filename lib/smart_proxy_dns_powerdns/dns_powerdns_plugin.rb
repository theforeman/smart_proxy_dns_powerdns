require 'smart_proxy_dns_powerdns/dns_powerdns_version'

module Proxy::Dns::Powerdns
  class Plugin < ::Proxy::Provider
    plugin :dns_powerdns, ::Proxy::Dns::Powerdns::VERSION,
           :factory => proc { |attrs| ::Proxy::Dns::Powerdns::Record.record(attrs) }

    requires :dns, '>= 1.10'

    after_activation do
      require 'smart_proxy_dns_powerdns/dns_powerdns_main'
    end
  end
end
