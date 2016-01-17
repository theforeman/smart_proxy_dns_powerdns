require 'smart_proxy_dns_powerdns/dns_powerdns_version'

module Proxy::Dns::Powerdns
  class Plugin < ::Proxy::Provider
    plugin :dns_powerdns, ::Proxy::Dns::Powerdns::VERSION

    requires :dns, '>= 1.11'

    validate_presence :powerdns_backend

    after_activation do
      require 'smart_proxy_dns_powerdns/dns_powerdns_configuration_validator'
      ::Proxy::Dns::Powerdns::ConfigurationValidator.new.validate_settings!(settings)

      require 'smart_proxy_dns_powerdns/dns_powerdns_main'
      require 'smart_proxy_dns_powerdns/dependencies'
    end
  end
end
