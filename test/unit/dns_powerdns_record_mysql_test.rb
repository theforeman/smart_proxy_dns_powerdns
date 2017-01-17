require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require 'smart_proxy_dns_powerdns/backend/mysql'

class DnsPowerdnsBackendMysqlTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Backend::Mysql.new('localhost', 86400, 'sudo pdnssec',
                                                         'db.example.com', 'the_user',
                                                         'something_secure', 'db_pdns')
    @connection = mock()
    @provider.stubs(:connection).returns(@connection)
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
    assert_equal 'sudo pdnssec', @provider.pdnssec
    assert_equal 'db.example.com', @provider.hostname
    assert_equal 'the_user', @provider.username
    assert_equal 'something_secure', @provider.password
    assert_equal 'db_pdns', @provider.database
  end

  def test_get_zone_with_existing_zone
    @connection.expects(:escape).with('test.example.com').returns('test.example.com')
    @connection.expects(:query).with("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE 'test.example.com' LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1").returns([{'id' => 1, 'name' => 'example.com'}])

    assert_equal(@provider.get_zone('test.example.com'), {'id' => 1, 'name' => 'example.com'})
  end

  def test_get_zone_without_existing_zone
    @connection.expects(:escape).with('test.example.com').returns('test.example.com')
    @connection.expects(:query).with("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE 'test.example.com' LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1").returns([])

    assert_raise(Proxy::Dns::Error) { @provider.get_zone('test.example.com') }
  end

  def test_create_record
    @connection.expects(:escape).with('test.example.com').returns('test.example.com')
    @connection.expects(:escape).with('A').returns('A')
    @connection.expects(:escape).with('10.1.1.1').returns('10.1.1.1')
    @connection.expects(:query).with("INSERT INTO records (domain_id, name, ttl, content, type, change_date) VALUES (1, 'test.example.com', 86400, '10.1.1.1', 'A', UNIX_TIMESTAMP())")
    @connection.expects(:affected_rows).returns(1)

    assert @provider.create_record(1, 'test.example.com', 'A', '10.1.1.1')
  end

  def test_delete_record
    @connection.expects(:escape).with('test.example.com').returns('test.example.com')
    @connection.expects(:escape).with('A').returns('A')
    @connection.expects(:query).with("DELETE FROM records WHERE domain_id=1 AND name='test.example.com' AND type='A'")
    @connection.expects(:affected_rows).returns(1)
    @connection.expects(:query).with("UPDATE records SET change_date=UNIX_TIMESTAMP() WHERE domain_id=1 AND type='SOA'")
    @connection.expects(:affected_rows).returns(1)
    assert @provider.delete_record(1, 'test.example.com', 'A')
  end

  def test_delete_no_record
    @connection.expects(:escape).with('test.example.com').returns('test.example.com')
    @connection.expects(:escape).with('A').returns('A')
    @connection.expects(:query).with("DELETE FROM records WHERE domain_id=1 AND name='test.example.com' AND type='A'")
    @connection.expects(:affected_rows).returns(0)

    assert_false @provider.delete_record(1, 'test.example.com', 'A')
  end

end
