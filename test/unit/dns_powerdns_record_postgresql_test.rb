require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_plugin'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require 'smart_proxy_dns_powerdns/backend/postgresql'

class DnsPowerdnsBackendPostgresqlTest < Test::Unit::TestCase
  # Test that correct initialization works
  def test_initialize_dummy_with_settings
    Proxy::Dns::Powerdns::Plugin.load_test_settings(:powerdns_postgresql_connection => 'dbname=powerdns')
    provider = klass.new
    assert_equal 'dbname=powerdns', provider.connection_str
  end

  private

  def klass
    Proxy::Dns::Powerdns::Backend::Postgresql
  end
end
