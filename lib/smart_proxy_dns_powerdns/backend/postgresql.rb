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
      result = connection.exec_params("INSERT INTO records (domain_id, name, ttl, content, type, change_date) VALUES ($1::int, $2, $3::int, $4, $5, extract(epoch from now()))", [domain_id, name, ttl, content, type])
      result.cmdtuples == 1
    end

    def delete_record domain_id, name, type
      result = connection.exec_params("DELETE FROM records WHERE domain_id=$1::int AND name=$2 AND type=$3", [domain_id, name, type])
      return false if result.cmdtuples == 0

      result = connection.exec_params("UPDATE records SET change_date=extract(epoch from now()) WHERE domain_id=$1::int AND type='SOA'", [domain_id])
      affected_rows = result.cmdtuples
      if affected_rows > 1
        logger.warning("Updated multiple SOA records (host=#{name}, domain_id=#{domain_id}). Check your zone records for duplicate SOA entries.")
      elsif affected_rows == 0
        logger.info("No SOA record updated (host=#{name}, domain_id=#{domain_id}). This can be caused by either a missing SOA record for the zone or consecutive updates of the same zone during the same second.")
      end
      true
    end
  end
end
