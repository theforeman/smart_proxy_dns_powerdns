#!/bin/bash -xe

create_database() {
	echo "CREATE DATABASE $DB_NAME" | $DB_CMD
}

init_database() {
	local prog=""

	for schema in /usr/share/doc/pdns{,-backend-${DB}}/schema.${DB}.sql{,.gz,.bz2} /usr/share/dbconfig-common/data/pdns-backend-${DB}/install/${DB} ; do
		if [[ -e "$schema" ]] ; then
			if [[ "${schema%%.gz}" != "$schema" ]] ; then
				echo "Extension is .gz"
				prog=zcat
			elif [[ "${schema%%.bz2}" != "$schema" ]] ; then
				echo "Extension is .bz2"
				prog=bzcat
			else
				echo "Extension is .sql"
				prog=cat
			fi
			break
		fi
	done

	if [[ "$prog" == "" ]] ; then
		echo "Could not find schema"
		exit 1
	fi

	echo "Importing schema $schema"
	$prog "$schema" | $DB_CMD $DB_NAME

	echo "Creating example.com and in-addr.arpa zones"
	echo "INSERT INTO domains (name, type) VALUES ('example.com', 'master'), ('in-addr.arpa', 'master'); INSERT INTO records (domain_id, name, type, content) SELECT id domain_id, name, 'SOA', 'ns1.example.com hostmaster.example.com. 0 3600 1800 1209600 3600' FROM domains WHERE NOT EXISTS (SELECT 1 FROM records WHERE records.domain_id=domains.id AND records.name=domains.name AND type='SOA');" | $DB_CMD $DB_NAME
}

config_pdns() {
	cat > /tmp/pdns.conf <<-EOF
	launch=g$DB
	local-port=5300
	socket-dir=/tmp
	g$DB-dnssec=true
	g$DB-user=$DB_USER
	g$DB-dbname=$DB_NAME
	EOF
}

start_pdns() {
	/usr/sbin/pdns_server $PDNS_ARGS &
}

. $(dirname $0)/config.sh
create_database
init_database
config_pdns
start_pdns
