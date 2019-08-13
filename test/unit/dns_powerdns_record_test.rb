require 'test_helper'

require 'smart_proxy_dns_powerdns/dns_powerdns_main'

class DnsPowerdnsRecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Powerdns::Record.new('localhost', 86400,
                                                 'http://localhost:8081/api/v1/servers/localhost',
                                                 'apikey')
  end

  def test_initialize
    assert_equal 86400, @provider.ttl
    assert_equal 'http://localhost:8081/api/v1/servers/localhost', @provider.url
    assert_equal 'apikey', @provider.api_key
  end

  def test_do_create_success
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(true)

    assert @provider.do_create('test.example.com', '10.1.1.1', 'A')
  end

  def test_do_create_failure_in_create
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:create_record).with(1, 'test.example.com', 'A', '10.1.1.1').returns(false)

    assert_raise(Proxy::Dns::Error) do
      @provider.do_create('test.example.com', '10.1.1.1', 'A')
    end
  end

  def test_do_remove
    @provider.expects(:get_zone).with('test.example.com').returns({'id' => 1, 'name' => 'example.com'})
    @provider.expects(:delete_record).with(1, 'test.example.com', 'A').returns(true)

    assert @provider.do_remove('test.example.com', 'A')
  end

  def test_get_zone_with_existing_zone
    stub_request(:get, "http://localhost:8081/api/v1/servers/localhost/zones").
      with(:headers => {'X-Api-Key' => 'apikey'}).
      to_return(:body => '[{"id": "example.com.", "name": "example.com."}]')
    assert_equal @provider.get_zone('test.example.com'), {'id' => 'example.com.', 'name' => 'example.com.'}
  end

  def test_get_zone_with_existing_zone_absolute_record
    stub_request(:get, "http://localhost:8081/api/v1/servers/localhost/zones").
      with(:headers => {'X-Api-Key' => 'apikey'}).
      to_return(:body => '[{"id": "example.com.", "name": "example.com."}]')
    assert_equal @provider.get_zone('test.example.com.'), {'id' => 'example.com.', 'name' => 'example.com.'}
  end

  def test_get_zone_without_existing_zone
    stub_request(:get, "http://localhost:8081/api/v1/servers/localhost/zones").
      with(:headers => {'X-Api-Key' => 'apikey'}).
      to_return(:body => '[]')
    assert_raise(Proxy::Dns::Error) { @provider.get_zone('test.example.com') }
  end

  def test_create_a_record
    stub_request(:patch, "http://localhost:8081/api/v1/servers/localhost/zones/example.com.").
      with(
        :headers => {'X-Api-Key' => 'apikey', 'Content-Type' => 'application/json'},
        :body => '{"rrsets":[{"name":"test.example.com.","type":"A","ttl":86400,"changetype":"REPLACE","records":[{"content":"10.1.1.1","disabled":false}]}]}'
      )
    assert @provider.create_record('example.com.', 'test.example.com', 'A', '10.1.1.1')
  end

  def test_create_ptr_record
    stub_request(:patch, "http://localhost:8081/api/v1/servers/localhost/zones/example.com.").
      with(
        :headers => {'X-Api-Key' => 'apikey', 'Content-Type' => 'application/json'},
        :body => '{"rrsets":[{"name":"1.1.1.10.in-addr.arpa.","type":"PTR","ttl":86400,"changetype":"REPLACE","records":[{"content":"test.example.com.","disabled":false}]}]}'
      )
    assert @provider.create_record('example.com.', '1.1.1.10.in-addr.arpa', 'PTR', 'test.example.com')
  end

  def test_delete_record
    stub_request(:patch, "http://localhost:8081/api/v1/servers/localhost/zones/example.com.").
      with(
        :headers => {'X-Api-Key' => 'apikey', 'Content-Type' => 'application/json'},
        :body => '{"rrsets":[{"name":"test.example.com.","type":"A","changetype":"DELETE","records":[]}]}'
      )
    assert @provider.delete_record('example.com.', 'test.example.com', 'A')
  end
end
