module ::Proxy::Dns::Powerdns
  class PluginConfiguration
    def load_classes
      require 'dns_common/dns_common'
      require 'smart_proxy_dns_powerdns/dns_powerdns_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      valid_backends = ['mysql', 'postgresql', 'rest', 'dummy']
      backend = settings[:powerdns_backend]
      unless valid_backends.include?(backend)
        raise ::Proxy::Error::ConfigurationError.new("Invalid backend, is expected to be mysql, postgresql, rest or dummy")
      end

      begin
        require "smart_proxy_dns_powerdns/backend/#{backend}"
      rescue LoadError, e
        raise ::Proxy::Error::ConfigurationError.new("Failed to load backend #{backend}: #{e}")
      end

      case backend
      when 'mysql'
        container_instance.dependency :dns_provider, (lambda do
          Proxy::Dns::Powerdns::Backend::Mysql.new(
              settings[:dns_server],
              settings[:dns_ttl],
              settings[:powerdns_pdnssec],
              settings[:powerdns_mysql_hostname] || 'localhost',
              settings[:powerdns_mysql_username] || 'powerdns',
              settings[:powerdns_mysql_password] || '',
              settings[:powerdns_mysql_database] || 'pdns',
          )
        end)
      when 'postgresql'
        container_instance.dependency :dns_provider, (lambda do
          Proxy::Dns::Powerdns::Backend::Postgresql.new(
            settings[:dns_server],
            settings[:dns_ttl],
            settings[:powerdns_pdnssec],
            settings[:powerdns_postgresql_connection] || 'dbname=pdns',
        )
        end)
      when 'rest'
        raise ::Proxy::Error::ConfigurationError.new("Setting powerdns_rest_api_key must be non-empty") unless settings[:powerdns_rest_api_key]

        container_instance.dependency :dns_provider, (lambda do
          Proxy::Dns::Powerdns::Backend::Rest.new(
            settings[:dns_server],
            settings[:dns_ttl],
            settings[:powerdns_rest_url] || 'http://localhost:8081/api/v1/servers/localhost',
            settings[:powerdns_rest_api_key],
          )
        end)
      when 'dummy'
        container_instance.dependency :dns_provider, (lambda do
          Proxy::Dns::Powerdns::Backend::Dummy.new(
            settings[:dns_server],
            settings[:dns_ttl],
          )
        end)
      end
    end
  end
end
