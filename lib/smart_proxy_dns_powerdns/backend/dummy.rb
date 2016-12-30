module Proxy::Dns::Powerdns::Backend
  class Dummy < ::Proxy::Dns::Powerdns::Record

    def initialize(a_server = nil, a_ttl = nil)
      super(a_server, a_ttl)
    end

    def get_zone name
      {
        'id'   => 1,
        'name' => name.partition('.')[2]
      }
    end

    def create_record domain_id, name, content, type
      false
    end

    def delete_record domain_id, name, type
      false
    end
  end
end

