require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'

class DnsPowerdnsRecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Record.new('localhost', 86400, 'echo pdnssec')
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
    assert_equal 'echo pdnssec', @provider.pdnssec
  end

  def test_do_create_success
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.do_create('test.example.com', '10.1.1.1', 'A')
  end

  def test_do_create_failure_in_create
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(false)

    assert_raise(Proxy::Dns::Error) do
      @provider.do_create('test.example.com', '10.1.1.1', 'A')
    end
  end

  def test_do_create_failure_in_rectify
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(false)

    assert_raise(Proxy::Dns::Error) do
      @provider.do_create('test.example.com', '10.1.1.1', 'A')
    end
  end

  def test_do_remove
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)
    @provider.expects(:rectify_zone).with('example.com').returns(true)

    assert @provider.do_remove('test.example.com', 'A')
  end

  def test_rectify_zone_success
    @provider.logger.expects(:debug).with('running: echo pdnssec rectify-zone "example.com"')

    assert_true @provider.rectify_zone 'example.com'
  end

  def test_rectify_zone_failure
    @provider = Proxy::Dns::Powerdns::Record.new('localhost', 86400, 'false')

    @provider.logger.expects(:debug).with('running: false rectify-zone "example.com"')
    @provider.logger.expects(:debug).with('false (exit: 1) says: ')

    assert_false @provider.rectify_zone 'example.com'
  end

  def test_rectify_zone_no_pdnssec
    @provider = Proxy::Dns::Powerdns::Record.new('localhost', 86400, nil)

    @provider.logger.stubs(:debug).raises(Exception)

    assert_true @provider.rectify_zone 'example.com'
  end
end
