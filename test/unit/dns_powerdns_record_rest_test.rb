require 'test_helper'
require 'webmock/test_unit'

require 'smart_proxy_dns_powerdns/dns_powerdns_plugin'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require 'smart_proxy_dns_powerdns/backend/rest'

class DnsPowerdnsBackendRestTest < Test::Unit::TestCase
  # Test that correct initialization works
  def test_initialize_dummy_with_settings
    provider = instance
    assert_equal 'http://localhost:8081/servers/localhost', provider.url
    assert_equal 'apikey', provider.api_key
  end

  def test_get_zone_with_existing_zone
    stub_request(:get, "http://localhost:8081/servers/localhost/zones").
      with(:headers => {'X-Api-Key' => 'apikey'}).
      to_return(:body => '[{"id": "example.com.", "name": "example.com."}]')
    assert_equal instance.get_zone('test.example.com'), {'id' => 'example.com.', 'name' => 'example.com.'}
  end

  def test_get_zone_with_existing_zone_absolute_record
    stub_request(:get, "http://localhost:8081/servers/localhost/zones").
      with(:headers => {'X-Api-Key' => 'apikey'}).
      to_return(:body => '[{"id": "example.com.", "name": "example.com."}]')
    assert_equal instance.get_zone('test.example.com.'), {'id' => 'example.com.', 'name' => 'example.com.'}
  end

  def test_get_zone_without_existing_zone
    stub_request(:get, "http://localhost:8081/servers/localhost/zones").
      with(:headers => {'X-Api-Key' => 'apikey'}).
      to_return(:body => '[]')
    assert_raise(Proxy::Dns::Error) { instance.get_zone('test.example.com') }
  end

  def test_create_a_record
    stub_request(:patch, "http://localhost:8081/servers/localhost/zones/example.com.").
      with(
        :headers => {'X-Api-Key' => 'apikey', 'Content-Type' => 'application/json'},
        :body => '{"rrsets":[{"name":"test.example.com.","type":"A","ttl":86400,"changetype":"REPLACE","records":[{"content":"10.1.1.1","disabled":false}]}]}'
      )
    assert instance.create_record('example.com.', 'test.example.com', 'A', '10.1.1.1')
  end

  def test_create_ptr_record
    stub_request(:patch, "http://localhost:8081/servers/localhost/zones/example.com.").
      with(
        :headers => {'X-Api-Key' => 'apikey', 'Content-Type' => 'application/json'},
        :body => '{"rrsets":[{"name":"1.1.1.10.in-addr.arpa.","type":"PTR","ttl":86400,"changetype":"REPLACE","records":[{"content":"test.example.com.","disabled":false}]}]}'
      )
    assert instance.create_record('example.com.', '1.1.1.10.in-addr.arpa', 'PTR', 'test.example.com')
  end

  def test_delete_record
    stub_request(:patch, "http://localhost:8081/servers/localhost/zones/example.com.").
      with(
        :headers => {'X-Api-Key' => 'apikey', 'Content-Type' => 'application/json'},
        :body => '{"rrsets":[{"name":"test.example.com.","type":"A","changetype":"DELETE","records":[]}]}'
      )
    assert instance.delete_record('example.com.', 'test.example.com', 'A')
  end

  private

  def instance
    Proxy::Dns::Powerdns::Plugin.load_test_settings(
      :powerdns_rest_url => 'http://localhost:8081/servers/localhost',
      :powerdns_rest_api_key => 'apikey',
    )
    Proxy::Dns::Powerdns::Backend::Rest.new
  end
end
