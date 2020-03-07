#!/bin/bash

set -e

RES='result-02-sort-int-mysqlslap'

mkdir $RES

# Generate the scripts
bash filesort-bench1/02-make-fill-sort-int-tables.sh > $RES/fill-sort-int-tables.sql
bash filesort-bench1/02-make-clean-sort-int-tables.sh > $RES/clean-sort-int-tables.sql

for SERVER in  mariadb-10.5  mariadb-10.5-mdev6915-ext ; do

bash prepare-server.sh -m $SERVER
source $SERVER-vars.sh

$MYSQL $MYSQL_ARGS test < $RES/fill-sort-int-tables.sql  | tee $RES/fill-log-$SERVER.txt

for size in 100000 500000 1000000 2000000 4000000 ; do

$MYSQLSLAP $MYSQL_ARGS \
  --create-schema=test --no-drop \
  --query="select a, b from t_int_$size order by a limit 100" \
  --concurrency=30 --iterations=400 | tee -a $RES/result-$SERVER.txt

done 

$MYSQL $MYSQL_ARGS test < $RES/clean-sort-int-tables.sql | tee $RES/clean-log-$SERVER.txt

done
exit 0;

