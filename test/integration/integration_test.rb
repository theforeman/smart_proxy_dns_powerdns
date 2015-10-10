require 'test_helper'

require 'ipaddr'
require 'net/http'

class DnsPowerdnsIntegrationTest < Test::Unit::TestCase

  def test_forward_dns
    data = {'fqdn' => fqdn, 'value' => ip, 'type' => 'A'}

    uri = URI(smart_proxy_url)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(URI(smart_proxy_url + 'dns/'))
      request.form_data = data
      response = http.request request
      assert_equal(200, response.code.to_i)

      addresses = resolver.getresources(data['fqdn'], Resolv::DNS::Resource::IN::A)
      assert_equal([Resolv::DNS::Resource::IN::A.new(Resolv::IPv4.create(data['value']))], addresses)

      request = Net::HTTP::Delete.new(URI(smart_proxy_url + 'dns/' + data['fqdn']))
      response = http.request request
      assert_equal(200, response.code.to_i)

      assert(purge_cache data['fqdn'])

      addresses = resolver.getresources(data['fqdn'], Resolv::DNS::Resource::IN::A)
      assert_equal([], addresses)
    end
  end

  def test_reverse_dns
    data = {'fqdn' => fqdn, 'value' => ip, 'type' => 'PTR'}

    uri = URI(smart_proxy_url)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(URI(smart_proxy_url + 'dns/'))
      request.form_data = data
      response = http.request request
      assert_equal(200, response.code.to_i)

      name = Resolv::IPv4.create(data['value']).to_name.to_s

      addresses = resolver.getresources(name, Resolv::DNS::Resource::IN::PTR)
      assert_equal([Resolv::DNS::Resource::IN::PTR.new(Resolv::DNS::Name.create(data['fqdn'] + '.'))], addresses, "#{data['value']} should reverse to #{data['fqdn']}")

      request = Net::HTTP::Delete.new(URI(smart_proxy_url + 'dns/' + data['fqdn']))
      response = http.request request
      assert_equal(200, response.code.to_i)

      assert(purge_cache name)

      addresses = resolver.getresources(data['fqdn'], Resolv::DNS::Resource::IN::PTR)
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
