require 'pg'

module Proxy::Dns::Powerdns::Backend
  class Postgresql < ::Proxy::Dns::Powerdns::Record

    attr_reader :connection_str

    def initialize(a_server, a_ttl, pdnssec, connection)
      @connection_str = connection

      super(a_server, a_ttl, pdnssec)
    end

    def connection
      @connection ||= PG.connect(connection_str)
    end

    def get_zone name
      domain = nil

      connection.exec_params("SELECT LENGTH(name) domain_length, id, name FROM domains WHERE $1 LIKE CONCAT('%%.', name) ORDER BY domain_length DESC LIMIT 1", [name]) do |result|
        result.each do |row|
          domain = row
        end
      end

      raise Proxy::Dns::Error, "Unable to determine zone for #{name}. Zone must exist in PowerDNS." unless domain

      domain
    end

    def create_record domain_id, name, type, content
      result = connection.exec_params("INSERT INTO records (domain_id, name, ttl, content, type) VALUES ($1::int, $2, $3::int, $4, $5)", [domain_id, name, ttl, content, type])
      result.cmdtuples == 1
    end

    def delete_record domain_id, name, type
      result = connection.exec_params("DELETE FROM records WHERE domain_id=$1::int AND name=$2 AND type=$3", [domain_id, name, type])
      result.cmdtuples >= 1
    end
  end
end
