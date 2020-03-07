#!/bin/bash

set -e

RES='result-sort-int'

mkdir $RES

bash filesort-bench1/01-make-sort-int-bench.sh > $RES/sort-int-bench.sql

bash prepare-server.sh -m mariadb-10.5
source mariadb-10.5-vars.sh

$MYSQL $MYSQL_ARGS test < $RES/sort-int-bench.sql | tee $RES/sort-int-mariadb-10.5.txt

source mariadb-10.5-mdev6915-ext-vars.sh
bash prepare-server.sh -m mariadb-10.5-mdev6915-ext
$MYSQL $MYSQL_ARGS test < $RES/sort-int-bench.sql | tee $RES/sort-int-mariadb-10.5-mdev6915-ext.txt


