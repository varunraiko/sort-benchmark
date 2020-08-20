#!/bin/bash

set -e

RES='result-varchars'

#mkdir $RES

bash filesort-bench1/$1/06-make-collect-results.sh > $RES/collect-results.sql

for SERVER in  mariadb-10.5-mdev21829 mariadb-10.5 ; do
  
  bash prepare-server.sh -r -m $SERVER
  source $SERVER-vars.sh

  $MYSQL $MYSQL_ARGS test < $RES/collect-results.sql | tee $RES/results-$SERVER.txt

done
