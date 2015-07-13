require 'dns/dns'
require 'ipaddr'
require 'mysql2'

module Proxy::Dns::Powerdns
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_reader :mysql_connection

    def self.record(attrs = {})
      new(attrs.merge(
        :powerdns_mysql_hostname => ::Proxy::Dns::Powerdns::Plugin.settings.powerdns_mysql_hostname,
        :powerdns_mysql_username => ::Proxy::Dns::Powerdns::Plugin.settings.powerdns_mysql_username,
        :powerdns_mysql_password => ::Proxy::Dns::Powerdns::Plugin.settings.powerdns_mysql_password,
        :powerdns_mysql_database => ::Proxy::Dns::Powerdns::Plugin.settings.powerdns_mysql_database
      ))
    end

    def initialize options = {}
      raise "dns_powerdns provider needs 'powerdns_mysql_hostname' option" unless options[:powerdns_mysql_hostname]
      raise "dns_powerdns provider needs 'powerdns_mysql_username' option" unless options[:powerdns_mysql_username]
      raise "dns_powerdns provider needs 'powerdns_mysql_password' option" unless options[:powerdns_mysql_password]
      raise "dns_powerdns provider needs 'powerdns_mysql_database' option" unless options[:powerdns_mysql_database]
      @mysql_connection = Mysql2::Client.new(
        :host => options[:powerdns_mysql_hostname],
        :username => options[:powerdns_mysql_username],
        :password => options[:powerdns_mysql_password],
        :database => options[:powerdns_mysql_database]
      )

      # Normalize the somewhat weird PTR API spec to name / content
      case options[:type]
      when "PTR"
        @name = IPAddr.new(options[:value]).reverse
        @content = options[:fqdn]
      else
        @name = options[:fqdn]
        @content = options[:value]
      end

      super(options)
    end

    def create
      raise Proxy::Dns::Error, "Unable to determine zone. Zone must exist in PowerDNS." unless domain_id

      if ip = dns_find(@name)
        raise Proxy::Dns::Collision, "#{@name} is already in use by #{ip}"
      end

      create_record(domain_id, @name, @ttl, @content, @type)
    end

    def remove
      delete_record(@name, @type)
    end

    private
    def domain_id
      id = nil

      name = mysql_connection.escape(@name)
      mysql_connection.query("SELECT LENGTH(name) domain_length, id FROM domains WHERE '#{name}' LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1").each do |row|
        id = row["id"]
      end

      id
    end

    private
    def dns_find key
      value = nil
      key = mysql_connection.escape(key)
      mysql_connection.query("SELECT content FROM records WHERE domain_id=#{domain_id} AND name = '#{key}' LIMIT 1").each do |row|
        value = row["content"]
      end
      value || false
    end

    private
    def create_record domain_id, name, ttl, content, type
      name = mysql_connection.escape(name)
      content = mysql_connection.escape(content)
      type = mysql_connection.escape(type)
      mysql_connection.query("INSERT INTO records (domain_id, name, ttl, content, type) VALUES (#{domain_id}, '#{name}', #{ttl.to_i}, '#{content}', '#{type}')")
      # TODO: run rectify-zone
      true
    end

    private
    def delete_record name, type
      name = mysql_connection.escape(name)
      type = mysql_connection.escape(type)
      mysql_connection.query("DELETE FROM records WHERE name='#{name}' AND type='#{type}'")
      # TODO: run rectify-zone
      true
    end
  end
end
