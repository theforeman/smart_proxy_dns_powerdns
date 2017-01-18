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
    mock_delete_tuples(0)
    assert_false run_delete_record
  end

  def test_delete_record_single_record
    mock_delete_tuples(1)
    mock_update_soa_tuples(1)

    assert_true run_delete_record
  end

  def test_delete_record_multiple_records
    mock_delete_tuples(2)
    mock_update_soa_tuples(1)

    assert_true run_delete_record
  end

  def test_delete_record_no_soa
    mock_delete_tuples(1)
    mock_update_soa_tuples(0)
    logger = mock()
    logger.expects(:info)
    @provider.stubs(:logger).returns(logger)

    assert_true run_delete_record
  end

  def test_delete_record_multiple_soa
    mock_delete_tuples(1)
    mock_update_soa_tuples(2)
    logger = mock()
    logger.expects(:warning)
    @provider.stubs(:logger).returns(logger)

    assert_true run_delete_record
  end

  private

  def mock_delete_tuples(cmdtuples)
    @connection.expects(:exec_params).
      with(query_delete, [domain_id, fqdn, record_type]).
      returns(mock(:cmdtuples => cmdtuples))
  end

  def mock_update_soa_tuples(cmdtuples)
    @connection.expects(:exec_params).
      with(query_update_soa, [domain_id]).
      returns(mock(:cmdtuples => cmdtuples))
  end

  def run_delete_record
    @provider.delete_record(domain_id, fqdn, record_type)
  end

  def domain
    'example.com'
  end

  def fqdn
    "test.#{domain}"
  end

  def domain_id
    1
  end

  def record_type
    'A'
  end

  def query_delete
    "DELETE FROM records WHERE domain_id=$1::int AND name=$2 AND type=$3"
  end

  def query_update_soa
    "UPDATE records SET change_date=extract(epoch from now()) WHERE domain_id=$1::int AND type='SOA'"
  end

end
