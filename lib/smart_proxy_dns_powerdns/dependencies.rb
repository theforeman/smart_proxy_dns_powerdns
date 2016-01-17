require 'dns_common/dependency_injection/dependencies'

class Proxy::Dns::DependencyInjection::Dependencies
  case Proxy::Dns::Powerdns::Plugin.settings.powerdns_backend
  when 'mysql'
    require 'smart_proxy_dns_powerdns/backend/mysql'
    dependency :dns_provider, Proxy::Dns::Powerdns::Backend::Mysql
  when 'postgresql'
    require 'smart_proxy_dns_powerdns/backend/postgresql'
    dependency :dns_provider, Proxy::Dns::Powerdns::Backend::Postgresql
  when 'dummy'
    require 'smart_proxy_dns_powerdns/backend/dummy'
    dependency :dns_provider, Proxy::Dns::Powerdns::Backend::Dummy
  end
end
