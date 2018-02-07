require 'test_helper'
require 'dns_common/dns_common'
require 'smart_proxy_dns_powerdns'
require 'smart_proxy_dns_powerdns/dns_powerdns_main'
require "rack/test"
require 'json'

module Proxy::Dns
  module DependencyInjection
    include Proxy::DependencyInjection::Accessors
    def container_instance; end
  end
end

require 'dns/dns_api'

ENV['RACK_ENV'] = 'test'

class InternalApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    app = Proxy::Dns::Api.new
    app.helpers.server = @server
    app
  end

  def setup
    @server = Proxy::Dns::Powerdns::Record.new('localhost', 3600)
  end

  def test_create_a_record
    name = "test.com"
    value = "192.168.33.33"
    type = "A"
    @server.expects(:do_create).with(name, value, type)
    post '/', :fqdn => name, :value => value, :type => type
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_create_ptr_record
    name = "test.com"
    value = "33.33.168.192.in-addr.arpa"
    type = "PTR"
    @server.expects(:do_create).with(value, name, type)
    post '/', :fqdn => name, :value => value, :type => type
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_delete_a_record
    name = "test.com"
    @server.expects(:do_remove).with(name, "A")
    delete name
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_delete_ptr_record
    name = "33.33.168.192.in-addr.arpa"
    @server.expects(:do_remove).with(name, "PTR")
    delete name
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end
end
