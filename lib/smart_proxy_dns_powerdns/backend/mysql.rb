require 'mysql2'

module Proxy::Dns::Powerdns::Backend
  class Mysql < ::Proxy::Dns::Powerdns::Record

    attr_reader :hostname, :username, :password, :database

    def initialize(a_server, a_ttl, pdnssec, hostname, username, password, database)
      @hostname = hostname
      @username = username
      @password = password
      @database = database

      super(a_server, a_ttl, pdnssec)
    end

    def connection
      @connection ||= Mysql2::Client.new(:host => hostname, :username => username, :password => password, :database => database)
    end

    def get_zone name
      domain = nil

      name = connection.escape(name)
      connection.query("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE '#{name}' LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1").each do |row|
        domain = row
      end

      raise Proxy::Dns::Error, "Unable to determine zone. Zone must exist in PowerDNS." unless domain

      domain
    end

    def create_record domain_id, name, type, content
      name = connection.escape(name)
      content = connection.escape(content)
      type = connection.escape(type)
      connection.query("INSERT INTO records (domain_id, name, ttl, content, type) VALUES (#{domain_id}, '#{name}', #{ttl.to_i}, '#{content}', '#{type}')")
      connection.affected_rows == 1
    end

    def delete_record domain_id, name, type
      name = connection.escape(name)
      type = connection.escape(type)
      connection.query("DELETE FROM records WHERE domain_id=#{domain_id} AND name='#{name}' AND type='#{type}'")
      connection.affected_rows >= 1
    end
  end
end
