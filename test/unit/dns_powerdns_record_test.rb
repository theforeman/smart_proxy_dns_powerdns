require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_plugin'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'

class DnsPowerdnsRecordTest < Test::Unit::TestCase
  # Test that correct initialization works
  def test_initialize_dummy_with_settings
    Proxy::Dns::Powerdns::Plugin.load_test_settings(:powerdns_pdnssec => 'sudo pdnssec')
    provider = klass.new
    assert_equal 'sudo pdnssec', provider.pdnssec
  end

  # Test A record creation
  def test_create_a
    instance = klass.new

    instance.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(-1)
    instance.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    instance.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)
    instance.expects(:rectify_zone).with('example.com').returns(true)

    assert instance.create_a_record(fqdn, ip)
  end

  # Test A record creation does nothing if the same record exists
  def test_create_a_duplicate
    instance = klass.new

    instance.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(0)

    assert_equal nil, instance.create_a_record(fqdn, ip)
  end

  # Test A record creation fails if the record exists
  def test_create_a_conflict
    instance = klass.new

    instance.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(1)

    assert_raise(Proxy::Dns::Collision) { instance.create_a_record(fqdn, ip) }
  end

  # Test PTR record creation
  def test_create_ptr
    instance = klass.new

    instance.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(-1)
    instance.expects(:get_zone).with('1.1.1.10.in-addr.arpa').returns({'id' => 1, 'name' => '1.1.10.in-addr.arpa'})
    instance.expects(:create_record).with(1, '1.1.1.10.in-addr.arpa', 'PTR', 'test.example.com').returns(true)
    instance.expects(:rectify_zone).with('1.1.10.in-addr.arpa').returns(true)

    assert instance.create_ptr_record(fqdn, reverse_ip)
  end

  # Test PTR record creation does nothing if the same record exists
  def test_create_ptr_duplicate
    instance = klass.new

    instance.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(0)

    assert_equal nil, instance.create_ptr_record(fqdn, reverse_ip)
  end

  # Test PTR record creation fails if the record exists
  def test_create_ptr_conflict
    instance = klass.new

    instance.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(1)

    assert_raise(Proxy::Dns::Collision) { instance.create_ptr_record(fqdn, reverse_ip) }
  end

  # Test A record removal
  def test_remove_a
    instance = klass.new

    instance.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    instance.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)
    instance.expects(:rectify_zone).with('example.com').returns(true)

    assert instance.remove_a_record(fqdn)
  end

  # Test PTR record removal
  def test_remove_ptr
    instance = klass.new

    instance.expects(:get_zone).with('1.1.1.10.in-addr.arpa').returns({'id' => 1, 'name' => '1.1.10.in-addr.arpa'})
    instance.expects(:delete_record).with(1, '1.1.1.10.in-addr.arpa', 'PTR').returns(true)
    instance.expects(:rectify_zone).with('1.1.10.in-addr.arpa').returns(true)

    assert instance.remove_ptr_record(reverse_ip)
  end

  def test_do_create
    instance = klass.new

    instance.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    instance.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)
    instance.expects(:rectify_zone).with('example.com').returns(true)

    assert instance.do_create('test.example.com', '10.1.1.1', 'A')
  end

  def test_do_remove
    instance = klass.new

    instance.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    instance.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)
    instance.expects(:rectify_zone).with('example.com').returns(true)

    assert instance.do_remove('test.example.com', 'A')
  end

  private

  def klass
    Proxy::Dns::Powerdns::Record
  end

  def fqdn
    'test.example.com'
  end

  def ip
    '10.1.1.1'
  end

  def reverse_ip
    '1.1.1.10.in-addr.arpa'
  end
end
