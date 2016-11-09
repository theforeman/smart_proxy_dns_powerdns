#!/bin/bash -xe

# PDNS_ARGS is set through .travis.yml
DB_NAME='pdnstravis'

if [ "$DB" = "mysql" ] ; then
	DB_USER='travis'
	DB_CMD="mysql"
elif [ "$DB" = "pgsql" ] ; then
	DB_USER='postgres'
	DB_CMD="psql -U $DB_USER"
else
	echo "Unknown database '$DB'"
	exit 1
fi

export DB_USER DB_NAME DB_CMD
