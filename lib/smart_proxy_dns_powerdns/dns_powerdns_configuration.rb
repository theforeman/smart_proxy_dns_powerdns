module ::Proxy::Dns::Powerdns
  class PluginConfiguration
    def load_classes
      require 'dns_common/dns_common'
      require 'smart_proxy_dns_powerdns/dns_powerdns_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      container_instance.dependency :dns_provider, (lambda do
        Proxy::Dns::Powerdns::Record.new(
          settings[:dns_server],
          settings[:dns_ttl],
          settings[:powerdns_rest_url],
          settings[:powerdns_rest_api_key],
        )
      end)
    end
  end
end
