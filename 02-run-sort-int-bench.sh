#!/bin/bash

set -e

RES='result-sort-int'

mkdir $RES

bash filesort-bench1/01-make-sort-int-bench.sh > $RES/sort-int-bench.sql

for SERVER in  mariadb-10.5-mdev6915-ext mariadb-10.5 ; do
  
  (cd $SERVER; git log -1) > $RES/tree-$SERVER.txt

  bash prepare-server.sh -m $SERVER
  source $SERVER-vars.sh

  $MYSQL $MYSQL_ARGS test < $RES/sort-int-bench.sql | tee $RES/sort-int-$SERVER.txt

  echo "TEST_RUN:,$SERVER" >> $RES/summary.txt
  tail -n 10 $RES/sort-int-$SERVER.txt >> $RES/summary.txt
done

cat $RES/summary.txt

