# SmartProxyDnsPowerdns

[![Gem Version](https://badge.fury.io/rb/smart_proxy_dns_powerdns.svg)](https://badge.fury.io/rb/smart_proxy_dns_powerdns)
[![Build Status](https://travis-ci.org/theforeman/smart_proxy_dns_powerdns.svg?branch=master)](https://travis-ci.org/theforeman/smart_proxy_dns_powerdns)
[![Coverage Status](https://coveralls.io/repos/github/theforeman/smart_proxy_dns_powerdns/badge.svg?branch=master)](https://coveralls.io/github/theforeman/smart_proxy_dns_powerdns?branch=master)

This plugin adds a new DNS provider for managing records in PowerDNS.

## Installation

See [How\_to\_Install\_a\_Smart-Proxy\_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)
for how to install Smart Proxy plugins

This plugin is compatible with Smart Proxy 1.13 or higher.

When installing using "gem", make sure to install the bundle file:

	echo "gem 'smart_proxy_dns_powerdns'" > /usr/share/foreman-proxy/bundler.d/dns_powerdns.rb

## Upgrading

### 0.3.0

* The minimum Smart Proxy version is now 1.13
* The REST backend is now the preferred backend. Users are encouraged to use it.

### 0.2.0

* The backend is a required parameter.

## Configuration

To enable this DNS provider, edit `/etc/foreman-proxy/settings.d/dns.yml` and set:

    :use_provider: dns_powerdns

Configuration options for this plugin are in `/etc/foreman-proxy/settings.d/dns_powerdns.yml`.

### REST

To use the REST backend, set the following parameters:

    :powerdns_backend: 'rest'
    :powerdns_rest_url: 'http://localhost:8081/api/v1/servers/localhost'
    :powerdns_rest_api_key: 'apikey'

**Note** only API v1 from PowerDNS 4.x is supported. The v0 API from 3.x is unsupported.

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

### DNSSEC with MySQL and PostgreSQL

In case you've enabled DNSSEC (as you should), all database backends require a rectify-zone after every zone change. The REST backend ignores this setting. The pdnssec command is configurable:

    :powerdns_pdnssec: 'pdnssec'

Or a more complex example:

    :powerdns_pdnssec: 'sudo pdnssec --config-name=myconfig'

Note that PowerDNS 4.x now uses `pdnsutil` rather than `pdnssec`.

### SOA autoserial with MySQL and PostgreSQL

PowerDNS (>= 3.3) provides a feature called `autoserial` that takes care of managing the serial of `SOA` records.

There are many options available regarding how PowerDNS generates the serial and details can be found looking for the `SOA-EDIT` option in PowerDNS.

One option is to let the PowerDNS backend determine the `SOA` serial using the biggest `change_date` of the records associated with the DNS domain.
`smart_proxy_dns_powerdns` uses this approach and updates the `change_date` field of changed records, setting them to the current timestamp of the database server, represented as **the number of seconds since EPOCH**.

* when a new record is created, its `change_date` is set accordingly
* when a record is deleted, the `change_date` of the `SOA` record for the domain is updated

### Updating the SOA serial when using the REST backend

When using the REST backend, the `change_date` of records isn't modified by this plugin.  To automatically increment the serial number of a zone, you can configure the [SOA-EDIT-API](https://doc.powerdns.com/authoritative/domainmetadata.html#soa-edit-api) zone metadata.  For example:

```shell
pdnsutil set-meta example.com SOA-EDIT-API DEFAULT
```

Other methods for managing the serial number are also available.  Alternatives to `SOA-EDIT-API` you might want to investigate include:
  * Installing database triggers that update the SOA record.
  * Reconfiguring powerdns's prepared statements such that the `change\_date` column gets updated when records are updated.

Full discussion of these methods is beyond the scope of this README.

## Contributing

Fork and send a Pull Request. Thanks!

### Running the integration tests

First you need to run the smart proxy on `http://localhost:8000` and a powerdns instance on `127.0.0.1:5300`.

It is assumed the powerdns instance has both the `example.com` and `in-addr.arpa` domains configured. If not, create them:

    INSERT INTO domains (name, type) VALUES ('example.com', 'master'), ('in-addr.arpa', 'master'), ('ip6.arpa', 'master');
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

