require 'json'
require 'net/http'
require 'resolv'

module Proxy::Dns::Powerdns::Backend
  extend ::Proxy::Log

  class Rest < ::Proxy::Dns::Powerdns::Record

    attr_reader :url, :api_key

    def initialize(a_server, a_ttl, url, api_key)
      @url = url
      @api_key = api_key

      super(a_server, a_ttl)
    end

    def get_zone name
      fqdn = Resolv::DNS::Name.create(name)
      fqdn = Resolv::DNS::Name.create(name + '.') unless fqdn.absolute?
      uri = URI("#{@url}/zones")

      result = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri
        request['X-API-Key'] = @api_key
        response = http.request request
        zones = JSON.parse(response.body) rescue []

        zones.select { |zone|
          domain = Resolv::DNS::Name.create(zone['name'])
          domain == fqdn or fqdn.subdomain_of?(domain)
        }.max_by { |zone| zone['name'].length }
      end

      raise Proxy::Dns::Error, "Unable to determine zone for #{name}. Zone must exist in PowerDNS." unless result

      result
    end

    def create_record domain_id, name, type, content
      content += '.' if ['PTR', 'CNAME'].include?(type)
      rrset = {
        :name => name + '.',
        :type => type,
        :ttl => @ttl.to_i,
        :changetype => :REPLACE,
        :records => [
          {
            :content => content,
            :disabled => false
          }
        ]
      }

      patch_records domain_id, rrset
    end

    def delete_record domain_id, name, type
      rrset = {
        :name => name + '.',
        :type => type,
        :changetype => :DELETE,
        :records => []
      }

      patch_records domain_id, rrset
    end

    private

    def patch_records domain_id, rrset
      uri = URI("#{@url}/zones/#{domain_id}")

      data = { :rrsets => [rrset] }

      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Patch.new uri
        request['X-API-Key'] = @api_key
        request['Content-Type'] = 'application/json'
        request.body = data.to_json
        response = http.request request
        unless response.is_a?(Net::HTTPSuccess)
          begin
            content = JSON.parse(response.body)
          rescue
            logger.debug "Failed to pach records for #{domain_id} with '#{rrset}': #{response.body}"
            raise Proxy::Dns::Error.new("Failed to patch records")
          end
          raise Proxy::Dns::Error.new("Failed to patch records: #{content['error']}")
        end
      end

      true
    end
  end
end
