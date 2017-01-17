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
end
