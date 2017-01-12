require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'

class DnsPowerdnsRecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Record.new('localhost', 86400, 'sudo pdnssec')
  end

  def setup_domain
    @provider.expects(:get_zone).with(fqdn).returns({'id' => domain_id, 'name' => domain})
    @provider.expects(:rectify_zone).with(domain).returns(true)
    @provider.expects(:update_soa).with(domain_id, domain).returns(true)
  end

  def setup_rev_ipv4_domain
    @provider.expects(:get_zone).with(reverse_ipv4).returns({'id' => domain_id, 'name' => reverse_ipv4_domain})
    @provider.expects(:rectify_zone).with(reverse_ipv4_domain).returns(true)
    @provider.expects(:update_soa).with(domain_id, reverse_ipv4_domain).returns(true)
  end

  def setup_rev_ipv6_domain
    @provider.expects(:get_zone).with(reverse_ipv6).returns({'id' => domain_id, 'name' => reverse_ipv6_domain})
    @provider.expects(:rectify_zone).with(reverse_ipv6_domain).returns(true)
    @provider.expects(:update_soa).with(domain_id, reverse_ipv6_domain).returns(true)
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
    assert_equal 'sudo pdnssec', @provider.pdnssec
  end

  # Test A record creation
  def test_create_a
    setup_domain
    @provider.expects(:a_record_conflicts).with(fqdn, ipv4).returns(-1)
    @provider.expects(:create_record).with(1, fqdn, 'A', ipv4).returns(true)

    assert @provider.create_a_record(fqdn, ipv4)
  end

  # Test A record creation does nothing if the same record exists
  def test_create_a_duplicate
    @provider.expects(:a_record_conflicts).with(fqdn, ipv4).returns(0)

    assert_equal nil, @provider.create_a_record(fqdn, ipv4)
  end

  # Test A record creation fails if the record exists
  def test_create_a_conflict
    @provider.expects(:a_record_conflicts).with(fqdn, ipv4).returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_a_record(fqdn, ipv4) }
  end

  # Test AAAA record creation
  def test_create_aaaa
    setup_domain
    @provider.expects(:aaaa_record_conflicts).with(fqdn, ipv6).returns(-1)
    @provider.expects(:create_record).with(1, fqdn, 'AAAA', ipv6).returns(true)

    assert @provider.create_aaaa_record(fqdn, ipv6)
  end

  # Test AAAA record creation does nothing if the same record exists
  def test_create_aaaa_duplicate
    @provider.expects(:aaaa_record_conflicts).with(fqdn, ipv6).returns(0)

    assert_equal nil, @provider.create_aaaa_record(fqdn, ipv6)
  end

  # Test AAAA record creation fails if the record exists
  def test_create_aaaa_conflict
    @provider.expects(:aaaa_record_conflicts).with(fqdn, ipv6).returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_aaaa_record(fqdn, ipv6) }
  end

  # Test CNAME record creation
  def test_create_cname
    setup_domain
    @provider.expects(:cname_record_conflicts).with(fqdn, cname).returns(-1)
    @provider.expects(:create_record).with(1, fqdn, 'CNAME', cname).returns(true)

    assert @provider.create_cname_record(fqdn, cname)
  end

  # Test CNAME record creation does nothing if the same record exists
  def test_create_cname_duplicate
    @provider.expects(:cname_record_conflicts).with(fqdn, cname).returns(0)

    assert_equal nil, @provider.create_cname_record(fqdn, cname)
  end

  # Test CNAME record creation fails if the record exists
  def test_create_cname_conflict
    @provider.expects(:cname_record_conflicts).with(fqdn, cname).returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_cname_record(fqdn, cname) }
  end

  # Test PTR record creation
  def test_create_ptr
    setup_rev_ipv4_domain
    @provider.expects(:ptr_record_conflicts).with(fqdn, ipv4).returns(-1)
    @provider.expects(:create_record).with(1, reverse_ipv4, 'PTR', fqdn).returns(true)

    assert @provider.create_ptr_record(fqdn, reverse_ipv4)
  end

  # Test PTR record creation does nothing if the same record exists
  def test_create_ptr_duplicate
    @provider.expects(:ptr_record_conflicts).with(fqdn, ipv4).returns(0)

    assert_equal nil, @provider.create_ptr_record(fqdn, reverse_ipv4)
  end

  # Test PTR record creation fails if the record exists
  def test_create_ptr_conflict
    @provider.expects(:ptr_record_conflicts).with(fqdn, ipv4).returns(1)

    assert_raise(Proxy::Dns::Collision) { @provider.create_ptr_record(fqdn, reverse_ipv4) }
  end

  # Test PTR record creation
  def test_create_ptr_ipv6
    setup_rev_ipv6_domain
    @provider.expects(:ptr_record_conflicts).with(fqdn, '2001:0db8:1234:abcd:0000:0000:0000:0001').returns(-1)
    @provider.expects(:create_record).with(1, reverse_ipv6, 'PTR', fqdn).returns(true)

    assert @provider.create_ptr_record(fqdn, reverse_ipv6)
  end

  # Test A record removal
  def test_remove_a
    setup_domain
    @provider.expects(:delete_record).with(1, fqdn, 'A').returns(true)
    assert @provider.remove_a_record(fqdn)
  end

  # Test PTR record removal
  def test_remove_ptr_ipv4
    setup_rev_ipv4_domain
    @provider.expects(:delete_record).with(1, reverse_ipv4, 'PTR').returns(true)

    assert @provider.remove_ptr_record(reverse_ipv4)
  end

  # Test PTR record removal
  def test_remove_ptr_ipv6
    setup_rev_ipv6_domain
    @provider.expects(:delete_record).with(1, reverse_ipv6, 'PTR').returns(true)

    assert @provider.remove_ptr_record(reverse_ipv6)
  end

  def test_do_create
    setup_domain
    @provider.expects(:create_record).with(domain_id, fqdn, 'A', ipv4).returns(true)

    assert @provider.do_create(fqdn, ipv4, 'A')
  end

  def test_do_remove
    setup_domain
    @provider.expects(:delete_record).with(1, fqdn, 'A').returns(true)

    assert @provider.do_remove(fqdn, 'A')
  end

  def test_get_soa
    @provider.expects(:get_soa_content).with(domain_id).returns([])
    assert_raise(Proxy::Dns::Error) { @provider.get_soa(domain_id, domain) }

    @provider.expects(:get_soa_content).with(domain_id).returns([soa, soa])
    assert_raise(Proxy::Dns::Error) { @provider.get_soa(domain_id, domain) }

    @provider.expects(:get_soa_content).with(domain_id).returns([soa])
    assert_equal @provider.get_soa(domain_id, domain), soa
  end

  def test_increment_soa_serial
    assert_raise(Proxy::Dns::Error) { @provider.increment_soa_serial('invalid soa', domain) }
    assert_raise(Proxy::Dns::Error) { @provider.increment_soa_serial("ns1.#{domain}. dns-admin.#{domain}. invalid_serial 900 900 1800 60", domain) }
    assert_equal @provider.increment_soa_serial(soa, domain), soa_updated
  end

  def test_update_soa
    @provider.expects(:get_soa).with(domain_id, domain).returns(soa)
    @provider.expects(:increment_soa_serial).with(soa, domain).returns(soa_updated)
    @provider.expects(:update_soa_content).with(domain_id, soa_updated).returns(true)

    assert @provider.update_soa(domain_id, domain)
  end

  private

  def domain
    'example.com'
  end

  def domain_id
    1
  end

  def fqdn
    "test.#{domain}"
  end

  def cname
    "alias.#{domain}"
  end

  def ipv4
    '10.1.1.1'
  end

  def reverse_ipv4
    '1.1.1.10.in-addr.arpa'
  end

  def reverse_ipv4_domain
    '1.1.10.in-addr.arpa'
  end

  def ipv6
    '2001:db8:1234:abcd::1'
  end

  def reverse_ipv6
    '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa'
  end

  def reverse_ipv6_domain
    'd.c.b.a.4.3.2.1.8.b.d.0.1.0.0.2.ip6.arpa'
  end

  def soa_serial
    144210844
  end

  def soa
    "ns1.#{domain}. dns-admin.#{domain}. #{soa_serial} 900 900 1800 60"
  end

  def soa_updated
    "ns1.#{domain}. dns-admin.#{domain}. #{soa_serial+1} 900 900 1800 60"
  end
end
