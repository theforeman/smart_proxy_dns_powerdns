require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require 'smart_proxy_dns_powerdns/backend/dummy'

class DnsPowerdnsBackendDummyTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Backend::Dummy.new('localhost', 86400)
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
  end

  def test_get_zone
    assert_equal @provider.get_zone('test.example.com'), {'id' => 1, 'name' => 'example.com'}
  end

  def test_create_record
    assert_false @provider.create_record(1, 'test.example.com', '10.1.2.3', 'A')
  end

  def test_delete_record
    assert_false @provider.delete_record(1, 'test.example.com', 'A')
  end
end
