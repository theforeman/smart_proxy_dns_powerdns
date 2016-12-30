require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_configuration'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'


class DnsPowerdnsProductionWiringTest < Test::Unit::TestCase
  def setup
    @container = ::Proxy::DependencyInjection::Container.new
    @config = ::Proxy::Dns::Powerdns::PluginConfiguration.new
  end

  def test_dns_provider_initialization_mysql_backend_minimal_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'mysql')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'localhost', provider.hostname
    assert_equal 'powerdns', provider.username
    assert_equal '', provider.password
    assert_equal 'pdns', provider.database
  end

  def test_dns_provider_initialization_mysql_backend_full_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'mysql',
                                              :powerdns_mysql_hostname => 'db.example.com',
                                              :powerdns_mysql_username => 'user',
                                              :powerdns_mysql_password => 'super secret',
                                              :powerdns_mysql_database => 'the_db',
                                             )

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'db.example.com', provider.hostname
    assert_equal 'user', provider.username
    assert_equal 'super secret', provider.password
    assert_equal 'the_db', provider.database
  end

  def test_dns_provider_initialization_postgresql_backend_minimal_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'postgresql')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'dbname=pdns', provider.connection_str
  end

  def test_dns_provider_initialization_postgresql_backend_full_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'postgresql',
                                              :powerdns_postgresql_connection => 'dbname=powerdns')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'dbname=powerdns', provider.connection_str
  end

  def test_dns_provider_initialization_rest_backend_invalid_settings
    assert_raise Proxy::Error::ConfigurationError do
      @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                                :powerdns_backend => 'rest')
    end
  end

  def test_dns_provider_initialization_rest_backend_minimal_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'rest',
                                              :powerdns_rest_api_key => 'apikey')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'http://localhost:8081/api/v1/servers/localhost', provider.url
    assert_equal 'apikey', provider.api_key
  end

  def test_dns_provider_initialization_rest_backend_full_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'rest',
                                              :powerdns_rest_url => 'http://apiserver',
                                              :powerdns_rest_api_key => 'apikey')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'http://apiserver', provider.url
    assert_equal 'apikey', provider.api_key
  end

  def test_dns_provider_initialization_dummy_backend
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_backend => 'dummy')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
  end

  def test_dns_provider_initialization_invalid_backend
    assert_raise Proxy::Error::ConfigurationError do
      @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                                :powerdns_backend => 'invalid')
    end
  end
end
