require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require 'smart_proxy_dns_powerdns/backend/postgresql'

class DnsPowerdnsBackendPostgresqlTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Backend::Postgresql.new('localhost', 86400, 'sudo pdnssec',
                                                              'dbname=powerdns')
    @connection = mock()
    @provider.stubs(:connection).returns(@connection)
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
    assert_equal 'sudo pdnssec', @provider.pdnssec
    assert_equal 'dbname=powerdns', @provider.connection_str
  end

  def test_get_zone_with_existing_zone
    @connection.expects(:exec_params).
      with("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE $1 LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1", ['test.example.com']).
      yields([{'id' => 1, 'name' => 'example.com'}])

    assert_equal(@provider.get_zone('test.example.com'), {'id' => 1, 'name' => 'example.com'})
  end

  def test_get_zone_without_existing_zone
    @connection.expects(:exec_params).
      with("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE $1 LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1", ['test.example.com']).
      yields([])

    assert_raise(Proxy::Dns::Error) { @provider.get_zone('test.example.com') }
  end

  def test_create_record
    @connection.expects(:exec_params).
      with("INSERT INTO records (domain_id, name, ttl, content, type, change_date) VALUES ($1::int, $2, $3::int, $4, $5, extract(epoch from now()))", [1, 'test.example.com', 86400, '10.1.1.1', 'A']).
      returns(mock(:cmdtuples => 1))

    assert_true @provider.create_record(1, 'test.example.com', 'A', '10.1.1.1')
  end

  def test_delete_record_no_records
    @connection.expects(:exec_params).
      with("DELETE FROM records WHERE domain_id=$1::int AND name=$2 AND type=$3", [1, 'test.example.com', 'A']).
      returns(mock(:cmdtuples => 0))

    assert_false @provider.delete_record(1, 'test.example.com', 'A')
  end

  def test_delete_record_single_record
    @connection.expects(:exec_params).
      with("DELETE FROM records WHERE domain_id=$1::int AND name=$2 AND type=$3", [1, 'test.example.com', 'A']).
      returns(mock(:cmdtuples => 1))
    @connection.expects(:exec_params).
      with("UPDATE records SET change_date=extract(epoch from now()) WHERE domain_id=$1::int AND type='SOA'", [1]).
      returns(mock(:cmdtuples => 1))

    assert_true @provider.delete_record(1, 'test.example.com', 'A')
  end

  def test_delete_record_multiple_records
    @connection.expects(:exec_params).
      with("DELETE FROM records WHERE domain_id=$1::int AND name=$2 AND type=$3", [1, 'test.example.com', 'A']).
      returns(mock(:cmdtuples => 2))
    @connection.expects(:exec_params).
      with("UPDATE records SET change_date=extract(epoch from now()) WHERE domain_id=$1::int AND type='SOA'", [1]).
      returns(mock(:cmdtuples => 1))

    assert_true @provider.delete_record(1, 'test.example.com', 'A')
  end
end
