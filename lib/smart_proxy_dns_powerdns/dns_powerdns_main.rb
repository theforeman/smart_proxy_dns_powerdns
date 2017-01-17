require 'dns/dns'
require 'dns_common/dns_common'

module Proxy::Dns::Powerdns
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_reader :pdnssec

    def initialize(a_server, a_ttl, pdnssec = nil)
      @pdnssec = pdnssec
      super(a_server, a_ttl)
    end

    def do_create(name, value, type)
      zone = get_zone(name)
      if create_record(zone['id'], name, type, value)
        raise Proxy::Dns::Error.new("Failed to rectify zone #{zone['name']}") unless rectify_zone(zone['name'])
      else
        raise Proxy::Dns::Error.new("Failed to insert record #{name} #{type} #{value}")
      end
      true
    end

    def do_remove(name, type)
      zone = get_zone(name)
      if delete_record(zone['id'], name, type)
        raise Proxy::Dns::Error.new("Failed to rectify zone #{name}") unless rectify_zone(zone['name'])
      end
      true
    end

    def get_zone(name)
      # TODO: backend specific
      raise Proxy::Dns::Error, "Unable to determine zone for #{name}. Zone must exist in PowerDNS."
    end

    def create_record(domain_id, name, type, content)
      # TODO: backend specific
      false
    end

    def delete_record(domain_id, name, type)
      # TODO: backend specific
      false
    end

    def rectify_zone domain
      if @pdnssec
        logger.debug("running: #{@pdnssec} rectify-zone \"#{domain}\"")
        pdnsout = %x(#{@pdnssec} rectify-zone "#{domain}" 2>&1)

        if $?.exitstatus != 0
          logger.debug("#{@pdnssec} (exit: #{$?.exitstatus}) says: #{pdnsout}")
          false
        else
          true
        end
      else
        true
      end
    end
  end
end
