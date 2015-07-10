require 'dns/dns'
require 'mysql'

module Proxy::Dns::Powerdns
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_reader :powerdns_mysql_hostname
    attr_reader :powerdns_mysql_username
    attr_reader :powerdns_mysql_password
    attr_reader :powerdns_mysql_database

    def initialize options = {}
      raise "dns_powerdns provider needs 'powerdns_mysql_hostname' option" unless options[:powerdns_mysql_hostname]
      raise "dns_powerdns provider needs 'powerdns_mysql_username' option" unless options[:powerdns_mysql_username]
      raise "dns_powerdns provider needs 'powerdns_mysql_password' option" unless options[:powerdns_mysql_password]
      raise "dns_powerdns provider needs 'powerdns_mysql_database' option" unless options[:powerdns_mysql_database]
      @mysql_connection = Mysql.new(options[:powerdns_mysql_hostname], options[:powerdns_mysql_username], options[:powerdns_mysql_password], options[:powerdns_mysql_database])
      super(options)
    end

    def create
      unless domain_id
        raise Proxy::DNS::Error, "Unable to determine zone. Zone must exist in PowerDNS."
      end

      case @type
        when "A"
          if ip = dns_find(@fqdn)
            raise Proxy::DNS::Collision, "#{@fqdn} is already in use by #{ip}"
          else
            @mysql_connection.query("INSERT INTO records (records.domain_id,records.name,records.ttl,records.content,records.type) VALUES (#{domain_id}, '#{@fqdn}', #{@ttl}, '#{@value}', '#{@type}');")
          end

          true
        when "PTR"
          ip = IPAddr.new(@value)
          ptrname = ip.reverse
          if name = dns_find(ptrname)
            raise Proxy::DNS::Collision, "#{@value} is already used by #{name}"
          else
            @mysql_connection.query("INSERT INTO records (records.domain_id,records.name,records.ttl,records.content,records.type) VALUES (#{domain_id}, '#{ptrname}', #{@ttl}, '#{@fqdn}', 'PTR');")
          end

          true
      end
    end

    def remove
      case @type
        when "A"
          @mysql_connection.query("DELETE FROM records WHERE name='#{@fqdn}' AND type='#{@type}'")

          true
        when "PTR"
          ip = IPAddr.new(@value)
          ptrname = ip.reverse
          @mysql_connection.query("DELETE FROM records WHERE name='#{ptrname}' AND type='#{@type}'")

          true
      end
    end

    private
    def domain_id
      case @type
      when "A"
        host_list = @fqdn.split(/\./);
        search_depth = 1
      when "PTR"
        host_list = @value.split(/\./).reverse;
        search_depth = 0
      end

      id = nil

      while id == nil && host_list.length != search_depth && host_list != nil
        domain = host_list * "."
        if @type == "PTR"
          domain.concat(".in-addr.arpa")
        end
        res = @mysql_connection.query("SELECT id FROM domains WHERE name = '#{domain}' LIMIT 1;")
        if res.num_rows() != 0
          id = res.fetch_row
        end
        res.free
        host_list.delete_at(0)
      end
      id
    end

    private
    def dns_find key
      value = nil
      res = @mysql_connection.query("SELECT content FROM records WHERE name = '#{key}' LIMIT 1;")
      if res.num_rows() != 0
        value = res.fetch_row
      end
      res.free
      if value != nil
        value
      else
        false
      end
    end
  end
end
