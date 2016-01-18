require 'test_helper'

require 'ipaddr'
require 'net/http'

class DnsPowerdnsIntegrationTest < Test::Unit::TestCase

  def test_forward_dns
    data = {'fqdn' => fqdn, 'value' => ip, 'type' => 'A'}

    uri = URI(smart_proxy_url)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(smart_proxy_url + 'dns/')
      request.form_data = data
      response = http.request request
      assert_equal(200, response.code.to_i)

      addresses = resolver.getaddresses(data['fqdn'])
      assert_equal([Resolv::IPv4.create(data['value'])], addresses, "#{data['fqdn']} should resolve to #{data['value']}")

      request = Net::HTTP::Delete.new(smart_proxy_url + 'dns/' + data['fqdn'])
      response = http.request request
      assert_equal(200, response.code.to_i)

      assert(purge_cache data['fqdn'])

      addresses = resolver.getaddresses(data['fqdn'])
      assert_equal([], addresses)
    end
  end

  def test_reverse_dns
    data = {'fqdn' => fqdn, 'value' => ip, 'type' => 'PTR'}

    uri = URI(smart_proxy_url)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(smart_proxy_url + 'dns/')
      request.form_data = data
      response = http.request request
      assert_equal(200, response.code.to_i)

      name = Resolv::IPv4.create(data['value']).to_name.to_s

      addresses = resolver.getnames(data['value'])
      assert_equal([Resolv::DNS::Name.create(data['fqdn'] + '.')], addresses, "#{data['value']} should reverse to #{data['fqdn']}")

      request = Net::HTTP::Delete.new(smart_proxy_url + 'dns/' + name)
      response = http.request request
      assert_equal(200, response.code.to_i)

      assert(purge_cache name)

      addresses = resolver.getnames(data['value'])
      assert_equal([], addresses)
    end
  end

  private

  def resolver
    Resolv::DNS.new(:nameserver_port => [['127.0.0.1', 5300]])
  end

  def smart_proxy_url
    'http://localhost:8000/'
  end

  def fqdn
    set = ('a' .. 'z').to_a + ('0' .. '9').to_a
    10.times.collect {|i| set[rand(set.size)] }.join + '.example.com'
  end

  def ip
    IPAddr.new(rand(2 ** 32), Socket::AF_INET).to_s
  end

  def purge_cache name
    %x{#{ENV['PDNS_CONTROL'] || "pdns_control"} purge "#{name}"}
    $? == 0
  end
end
