require 'smart_proxy_dns_powerdns/dns_powerdns_version'
require 'smart_proxy_dns_powerdns/dns_powerdns_configuration'

module Proxy::Dns::Powerdns
  class Plugin < ::Proxy::Provider
    plugin :dns_powerdns, ::Proxy::Dns::Powerdns::VERSION

    requires :dns, '>= 1.15'

    validate_presence :powerdns_rest_api_key
    default_settings :powerdns_rest_url => 'http://localhost:8081/api/v1/servers/localhost'

    load_classes ::Proxy::Dns::Powerdns::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::Dns::Powerdns::PluginConfiguration
  end
end
