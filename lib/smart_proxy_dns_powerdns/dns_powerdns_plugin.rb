require 'smart_proxy_dns_powerdns/dns_powerdns_version'
require 'smart_proxy_dns_powerdns/dns_powerdns_configuration'

module Proxy::Dns::Powerdns
  class Plugin < ::Proxy::Provider
    plugin :dns_powerdns, ::Proxy::Dns::Powerdns::VERSION

    requires :dns, '>= 1.13'

    validate_presence :powerdns_backend

    load_classes ::Proxy::Dns::Powerdns::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::Dns::Powerdns::PluginConfiguration
  end
end
