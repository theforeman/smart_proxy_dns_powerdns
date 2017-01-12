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
      unless create_record(zone['id'], name, type, value) and rectify_zone(zone['name'])
        raise Proxy::Dns::Error.new("Failed to create record #{name} #{type} #{value}")
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
        raise Proxy::Dns::Error.new("Failed to remove record #{name} #{type}") unless rectify_zone(zone['name'])
      end
      true
    end

    def get_zone(name)
      # TODO: backend specific
      raise Proxy::Dns::Error, "Unable to determine zone for #{name}. Zone must exist in PowerDNS."
    end

    def get_soa(domain_id, domain_name)
      soa = get_soa_content(domain_id)
      raise Proxy::Dns::Error, "Missing SOA record for domain #{domain_name}" if soa.empty?
      raise Proxy::Dns::Error, "Multiple SOA records for domain #{domain_name}" if soa.size != 1
      soa[0]
    end

    def get_soa_content(domain_id)
      # TODO: backend specific
      raise Proxy::Dns::Error, "Unable to get SOA record (feature not implemented)"
    end

    def update_soa_content(domain_id, new_soa)
      # TODO: backend specific
      raise Proxy::Dns::Error, "Unable to update SOA record (feature not implemented)"
    end

    def increment_soa_serial(soa, domain_name)
      # SOA record format (see RFC 1035, 3.3.13)
      #
      # MNAME    The <domain-name> of the name server that was the
      #          original or primary source of data for this zone.
      #
      # RNAME    A <domain-name> which specifies the mailbox of the
      #          person responsible for this zone.
      #
      # SERIAL   The unsigned 32 bit version number of the original copy
      #          of the zone.  Zone transfers preserve this value.  This
      #          value wraps and should be compared using sequence space
      #          arithmetic.
      #
      # REFRESH  A 32 bit time interval before the zone should be
      #          refreshed.
      #
      # RETRY    A 32 bit time interval that should elapse before a
      #          failed refresh should be retried.
      #
      # EXPIRE   A 32 bit time value that specifies the upper limit on
      #          the time interval that can elapse before the zone is no
      #          longer authoritative.
      #
      # MINIMUM  The unsigned 32 bit minimum TTL field that should be
      #          exported with any RR from this zone.
      field_count = 7
      elts = soa.split(' ')
      raise Proxy::Dns::Error, "Invalid SOA record format for domain #{domain_name} (invalid number of fields, expected=#{field_count}, actual=#{elts.size})" unless elts.size == field_count
      if elts[2].match(/^\d+$/)
        serial = elts[2].to_i
      else
        raise Proxy::Dns::Error, "Invalid SOA record format for domain #{domain_name} (serial '#{elts[2]}' is not a valid integer)"
      end
      serial += 1
      elts[2] = serial.to_s
      elts.join(' ')
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
        %x(#{@pdnssec} rectify-zone "#{domain}")

        $?.exitstatus == 0
      else
        true
      end
    end
  end
end
