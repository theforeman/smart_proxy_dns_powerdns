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

  def test_get_zone_with_existing_zone
    instance = klass.new

    connection = mock()
    instance.stubs(:connection).returns(connection)
    connection.expects(:escape).with('test.example.com').returns('test.example.com')
    connection.expects(:query).with("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE 'test.example.com' LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1").returns([{'id' => 1, 'name' => 'example.com'}])

    assert_equal(instance.get_zone('test.example.com'), {'id' => 1, 'name' => 'example.com'})
  end

  def test_get_zone_without_existing_zone
    instance = klass.new

    connection = mock()
    instance.stubs(:connection).returns(connection)
    connection.expects(:escape).with('test.example.com').returns('test.example.com')
    connection.expects(:query).with("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE 'test.example.com' LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1").returns([])

    assert_raise(Proxy::Dns::Error) { instance.get_zone('test.example.com') }
  end

  def test_create_record
    instance = klass.new

    connection = mock()
    instance.stubs(:connection).returns(connection)
    connection.expects(:escape).with('test.example.com').returns('test.example.com')
    connection.expects(:escape).with('A').returns('A')
    connection.expects(:escape).with('10.1.1.1').returns('10.1.1.1')
    connection.expects(:query).with("INSERT INTO records (domain_id, name, ttl, content, type) VALUES (1, 'test.example.com', 86400, '10.1.1.1', 'A')")
    connection.expects(:affected_rows).returns(1)

    assert instance.create_record(1, 'test.example.com', 'A', '10.1.1.1')
  end

  def test_delete_record
    instance = klass.new

    connection = mock()
    instance.stubs(:connection).returns(connection)
    connection.expects(:escape).with('test.example.com').returns('test.example.com')
    connection.expects(:escape).with('A').returns('A')
    connection.expects(:query).with("DELETE FROM records WHERE domain_id=1 AND name='test.example.com' AND type='A'")
    connection.expects(:affected_rows).returns(1)

    assert instance.delete_record(1, 'test.example.com', 'A')
  end

  private

  def klass
    Proxy::Dns::Powerdns::Backend::Mysql
  end
end
