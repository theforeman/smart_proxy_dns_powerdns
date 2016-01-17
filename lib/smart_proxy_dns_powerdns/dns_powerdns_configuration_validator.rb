require 'smart_proxy_dns_powerdns/dns_powerdns_plugin'

module Proxy::Dns::Powerdns
  class ConfigurationValidator
    def validate_settings!(settings)
      validate_choice(settings, :powerdns_backend, ['mysql', 'postgresql', 'dummy'])

      case settings.powerdns_backend
      when 'mysql'
        validate_presence(settings, [:powerdns_mysql_username, :powerdns_mysql_password, :powerdns_mysql_database])
      when 'postgresql'
        validate_presence(settings, [:powerdns_postgresql_connection])
      end
    end

    def validate_choice(settings, setting, choices)
      value = settings.send(setting)
      unless choices.include?(value)
        raise ::Proxy::Error::ConfigurationError, "Parameter '#{setting}' is expected to be one of #{choices.join(",")}"
      end
      true
    end

    def validate_presence(settings, names)
      names.each do |name|
        value = settings.send(name)
        raise ::Proxy::Error::ConfigurationError, "Parameter '#{name}' is expected to have a non-empty value" if value.nil? || value.to_s.empty?
      end
      true
    end
  end
end
