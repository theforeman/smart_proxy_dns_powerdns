# SmartProxyDnsPowerdns

This plugin adds a new DNS provider for managing records in PowerDNS.

## Installation

See [How_to_Install_a_Smart-Proxy_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)
for how to install Smart Proxy plugins

This plugin is compatible with Smart Proxy 1.11 or higher.

When installing using "gem", make sure to install the bundle file:

	echo "gem 'smart_proxy_dns_powerdns'" > /usr/share/foreman-proxy/bundler.d/dns_powerdns.rb

## Upgrading

Per version 0.2.0 the backend is a required parameter.

## Configuration

To enable this DNS provider, edit `/etc/foreman-proxy/settings.d/dns.yml` and set:

    :use_provider: dns_powerdns

Configuration options for this plugin are in `/etc/foreman-proxy/settings.d/dns_powerdns.yml`.

### MySQL

To use MySQL, set the following parameters:

    :powerdns_backend: 'mysql'
    :powerdns_mysql_hostname: 'localhost'
    :powerdns_mysql_username: 'powerdns'
    :powerdns_mysql_password: ''
    :powerdns_mysql_database: 'powerdns'

### PostgreSQL

To use PostgreSQL, set the following parameters:

    :powerdns_backend: 'postgresql'
    :powerdns_postgresql_connection: 'host=localhost user=powerdns password=mypassword dbname=powerdns'

### DNSSEC

In case you've enabled DNSSEC (as you should), a rectify-zone is required after every zone change. The pdnssec command is configurable:

    :powerdns_pdnssec: 'pdnssec'

Or a more complex example:

    :powerdns_pdnssec: 'sudo pdnssec --config-name=myconfig'

## Contributing

Fork and send a Pull Request. Thanks!

### Running the integration tests

First you need to run the smart proxy on `http://localhost:8000` and a powerdns instance on `127.0.0.1:5300`.

It is assumed the powerdns instance has both the `example.com` and `in-addr.arpa` domains configured. If not, create them:

    INSERT INTO domains (name, type) VALUES ('example.com', 'master'), ('in-addr.arpa', 'master');
    INSERT INTO records (domain_id, name, type, content) SELECT id domain_id, name, 'SOA', 'ns1.example.com hostmaster.example.com. 0 3600 1800 1209600 3600' FROM domains WHERE NOT EXISTS (SELECT 1 FROM records WHERE records.domain_id=domains.id AND records.name=domains.name AND type='SOA');

Then run the tests:

    bundle exec rake test:integration

## Copyright

Copyright (c) 2015 - 2016 Ewoud Kohl van Wijngaarden

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

