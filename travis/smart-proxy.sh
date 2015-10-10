#!/bin/bash -xe

. $(dirname $0)/config.sh

SMART_PROXY="$(bundle show smart_proxy)"

cat > "$SMART_PROXY/config/settings.yml" <<EOF
---
:http_port: 8000
:log_file: STDOUT
EOF

cat > "$SMART_PROXY/config/settings.d/dns.yml" <<EOF
---
:enabled: true
:use_provider: dns_powerdns
EOF

if [ "$DB" = "mysql" ] ; then
	cat > "$SMART_PROXY/config/settings.d/dns_powerdns.yml" <<-EOF
	---
	:powerdns_pdnssec: pdnssec $PDNS_ARGS
	:powerdns_backend: mysql
	:powerdns_mysql_hostname:
	:powerdns_mysql_username: $DB_USER
	:powerdns_mysql_password:
	:powerdns_mysql_database: $DB_NAME
	EOF
elif [ "$DB" = "pgsql" ] ; then
	cat > "$SMART_PROXY/config/settings.d/dns_powerdns.yml" <<-EOF
	---
	:powerdns_pdnssec: pdnssec $PDNS_ARGS
	:powerdns_backend: postgresql
	:powerdns_postgresql_connection: "user=$DB_USER dbname=$DB_NAME"
	EOF
else
	echo "Unknown database '$DB'"
	exit 1
fi

bundle exec smart-proxy &
