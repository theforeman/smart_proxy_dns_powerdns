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

    def create_a_record(fqdn, ip)
      case a_record_conflicts(fqdn, ip)
      when 1
        raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
      when 0 then
        return nil
      else
        do_create(fqdn, ip, "A")
      end
    end

    def create_aaaa_record(fqdn, ip)
      case aaaa_record_conflicts(fqdn, ip)
      when 1
        raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
      when 0 then
        return nil
      else
        do_create(fqdn, ip, "AAAA")
      end
    end

    def create_cname_record(fqdn, target)
      case cname_record_conflicts(fqdn, target)
      when 1 then
        raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
      when 0 then
        return nil
      else
        do_create(fqdn, target, "CNAME")
      end
    end

    def create_ptr_record(fqdn, ptr)
      case ptr_record_conflicts(fqdn, ptr_to_ip(ptr))
      when 1
        raise(Proxy::Dns::Collision, "'#{fqdn} 'is already in use")
      when 0 then
        return nil
      else
        do_create(ptr, fqdn, "PTR")
      end
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

    def remove_a_record(fqdn)
      do_remove(fqdn, "A")
    end

    def remove_aaaa_record(fqdn)
      do_remove(fqdn, "AAAA")
    end

    def remove_cname_record(fqdn)
      do_remove(fqdn, "CNAME")
    end

    def remove_ptr_record(ptr)
      do_remove(ptr, "PTR")
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
