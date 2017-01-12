require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'

class DnsPowerdnsRecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Record.new('localhost', 86400, 'sudo pdnssec')
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
    assert_equal 'sudo pdnssec', @provider.pdnssec
  end

  # Test A record creation
  def test_create_a
    @provider.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(-1)
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.create_a_record(fqdn, ipv4)
  end

  # Test A record creation does nothing if the same record exists
  def test_create_a_duplicate
    @provider.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(0)

    assert_equal nil, @provider.create_a_record(fqdn, ipv4)
  end

  # Test A record creation fails if the record exists
  def test_create_a_conflict
    @provider.expects(:a_record_conflicts).with('test.example.com', '10.1.1.1').returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_a_record(fqdn, ipv4) }
  end

  # Test AAAA record creation
  def test_create_aaaa
    @provider.expects(:aaaa_record_conflicts).with('test.example.com', '2001:db8:1234:abcd::1').returns(-1)
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'AAAA', '2001:db8:1234:abcd::1').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.create_aaaa_record(fqdn, ipv6)
  end

  # Test AAAA record creation does nothing if the same record exists
  def test_create_aaaa_duplicate
    @provider.expects(:aaaa_record_conflicts).with('test.example.com', '2001:db8:1234:abcd::1').returns(0)

    assert_equal nil, @provider.create_aaaa_record(fqdn, ipv6)
  end

  # Test AAAA record creation fails if the record exists
  def test_create_aaaa_conflict
    @provider.expects(:aaaa_record_conflicts).with('test.example.com', '2001:db8:1234:abcd::1').returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_aaaa_record(fqdn, ipv6) }
  end

  # Test CNAME record creation
  def test_create_cname
    @provider.expects(:cname_record_conflicts).with('test.example.com', 'something.example.com').returns(-1)
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'CNAME', 'something.example.com').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.create_cname_record(fqdn, 'something.example.com')
  end

  # Test CNAME record creation does nothing if the same record exists
  def test_create_cname_duplicate
    @provider.expects(:cname_record_conflicts).with('test.example.com', 'something.example.com').returns(0)

    assert_equal nil, @provider.create_cname_record(fqdn, 'something.example.com')
  end

  # Test CNAME record creation fails if the record exists
  def test_create_cname_conflict
    @provider.expects(:cname_record_conflicts).with('test.example.com', 'something.example.com').returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_cname_record(fqdn, 'something.example.com') }
  end

  # Test PTR record creation
  def test_create_ptr
    @provider.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(-1)
    @provider.expects(:get_zone).with('1.1.1.10.in-addr.arpa').returns({'id' => 1, 'name' => '1.1.10.in-addr.arpa'})
    @provider.expects(:create_record).with(1, '1.1.1.10.in-addr.arpa', 'PTR', 'test.example.com').returns(true)
    @provider.expects(:rectify_zone).with('1.1.10.in-addr.arpa').returns(true)

    assert @provider.create_ptr_record(fqdn, reverse_ipv4)
  end

  # Test PTR record creation does nothing if the same record exists
  def test_create_ptr_duplicate
    @provider.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(0)

    assert_equal nil, @provider.create_ptr_record(fqdn, reverse_ipv4)
  end

  # Test PTR record creation fails if the record exists
  def test_create_ptr_conflict
    @provider.expects(:ptr_record_conflicts).with('test.example.com', '10.1.1.1').returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_ptr_record(fqdn, reverse_ipv4) }
  end

  # Test PTR record creation
  def test_create_ptr_ipv6
    @provider.expects(:ptr_record_conflicts).with('test.example.com', '2001:0db8:1234:abcd:0000:0000:0000:0001').returns(-1)
    @provider.expects(:get_zone).with('1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa').returns({'id' => 1, 'name' => 'd.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa'})
    @provider.expects(:create_record).with(1, '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa', 'PTR', 'test.example.com').returns(true)
    @provider.expects(:rectify_zone).with('d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa').returns(true)

    assert @provider.create_ptr_record(fqdn, reverse_ipv6)
  end

  # Test A record removal
  def test_remove_a
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.remove_a_record(fqdn)
  end

  # Test PTR record removal
  def test_remove_ptr_ipv4
    @provider.expects(:get_zone).with('1.1.1.10.in-addr.arpa').returns({'id' => 1, 'name' => '1.1.10.in-addr.arpa'})
    @provider.expects(:delete_record).with(1, '1.1.1.10.in-addr.arpa', 'PTR').returns(true)
    @provider.expects(:rectify_zone).with('1.1.10.in-addr.arpa').returns(true)

    assert @provider.remove_ptr_record(reverse_ipv4)
  end

  # Test PTR record removal
  def test_remove_ptr_ipv6
    @provider.expects(:get_zone).with('1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa').returns({'id' => 1, 'name' => 'd.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa'})
    @provider.expects(:delete_record).with(1, '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa', 'PTR').returns(true)
    @provider.expects(:rectify_zone).with('d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa').returns(true)

    assert @provider.remove_ptr_record(reverse_ipv6)
  end

  def test_do_create
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.do_create('test.example.com', '10.1.1.1', 'A')
  end

  def test_do_remove
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.do_remove('test.example.com', 'A')
  end

  def test_get_soa
    soa = 'ns1.google.com. dns-admin.google.com. 144210844 900 900 1800 60'
    domain = 'google.com'
    domain_id = 1
    @provider.expects(:get_soa_content).with(domain_id).returns([])
    assert_raise(Proxy::Dns::Error) { @provider.get_soa(domain_id, domain) }

    @provider.expects(:get_soa_content).with(domain_id).returns([soa, soa])
    assert_raise(Proxy::Dns::Error) { @provider.get_soa(domain_id, domain) }

    @provider.expects(:get_soa_content).with(domain_id).returns([soa])
    assert_equal @provider.get_soa(domain_id, domain), soa
  end

  def test_increment_soa_serial
    prefix = 'ns2.google.com. dns-admin.google.com.'
    serial = 144200724
    suffix = '900 900 1800 60'
    assert_raise(Proxy::Dns::Error) { @provider.increment_soa_serial(prefix, 'google.com') }
    assert_raise(Proxy::Dns::Error) { @provider.increment_soa_serial("#{prefix} invalid_serial #{suffix}", 'google.com') }

    assert_equal @provider.increment_soa_serial("#{prefix} #{serial} #{suffix}", 'google.com'), "#{prefix} #{serial+1} #{suffix}"
  end

  def test_update_soa
    soa = 'ns1.google.com. dns-admin.google.com. 144210844 900 900 1800 60'
    new_soa = 'ns1.google.com. dns-admin.google.com. 144210845 900 900 1800 60'
    domain = 'google.com'
    domain_id = 1
    @provider.expects(:get_soa).with(domain_id, domain).returns(soa)
    @provider.expects(:increment_soa_serial).with(soa, domain).returns(new_soa)
    @provider.expects(:update_soa_content).with(domain_id, new_soa).returns(true)

    assert @provider.update_soa(domain_id, domain)
  end

  private

  def fqdn
    'test.example.com'
  end

  def ipv4
    '10.1.1.1'
  end

  def reverse_ipv4
    '1.1.1.10.in-addr.arpa'
  end

  def ipv6
    '2001:db8:1234:abcd::1'
  end

  def reverse_ipv6
    '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa'
  end
end
