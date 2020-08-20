#!/bin/bash

set -e

RES='result-varchars'

mkdir $RES

bash filesort-bench1/$1/06-make-varchar-bench.sh > $RES/varchar-bench.sql

for SERVER in  mariadb-10.5-mdev21829 mariadb-10.5 ; do
  
  (cd $SERVER; git log -1) > $RES/tree-$SERVER.txt

  bash prepare-server.sh -m $SERVER
  source $SERVER-vars.sh
  echo $SERVER
  $MYSQL $MYSQL_ARGS test < $RES/varchar-bench.sql | tee $RES/varchar-$SERVER.txt

done
