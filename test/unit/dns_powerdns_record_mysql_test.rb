require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_plugin'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require 'smart_proxy_dns_powerdns/backend/mysql'

class DnsPowerdnsBackendMysqlTest < Test::Unit::TestCase
  # Test that correct initialization works
  def test_initialize_dummy_with_settings
    Proxy::Dns::Powerdns::Plugin.load_test_settings(
      :powerdns_mysql_hostname => 'db.example.com',
      :powerdns_mysql_username => 'the_user',
      :powerdns_mysql_password => 'something_secure',
      :powerdns_mysql_database => 'db_pdns'
    )
    provider = klass.new
    assert_equal 'db.example.com', provider.hostname
    assert_equal 'the_user', provider.username
    assert_equal 'something_secure', provider.password
    assert_equal 'db_pdns', provider.database
  end

  private

  def klass
    Proxy::Dns::Powerdns::Backend::Mysql
  end
end
