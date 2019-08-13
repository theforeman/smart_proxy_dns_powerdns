require 'test_helper'
require 'webmock/test_unit'

require 'smart_proxy_dns_powerdns/dns_powerdns_configuration'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'


class DnsPowerdnsProductionWiringTest < Test::Unit::TestCase
  def setup
    @container = ::Proxy::DependencyInjection::Container.new
    @config = ::Proxy::Dns::Powerdns::PluginConfiguration.new
  end

  def test_dns_provider_initialization_rest_backend_full_settings
    @config.load_dependency_injection_wirings(@container, :dns_ttl => 999,
                                              :powerdns_rest_url => 'http://apiserver.example.com',
                                              :powerdns_rest_api_key => 'apikey')

    provider = @container.get_dependency(:dns_provider)

    assert_not_nil provider
    assert_equal 999, provider.ttl
    assert_equal 'http://apiserver.example.com', provider.url
    assert_equal 'apikey', provider.api_key
  end
end
