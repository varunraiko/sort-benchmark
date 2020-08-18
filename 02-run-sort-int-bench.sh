#!/bin/bash

set -e

RES='result-sort-int'

mkdir $RES

#
# $1 here is the benchmark you want to run
# 1) eits with packing   =>  pass eits
# 2) count(distinct col) =>  pass count_distinct
#

bash filesort-bench1/$1/01-make-sort-int-bench.sh > $RES/sort-int-bench.sql

for SERVER in  mariadb-10.5 mariadb-10.5-mdev21829 ; do
  
  (cd $SERVER; git log -1) > $RES/tree-$SERVER.txt

  bash prepare-server.sh -m $SERVER
  source $SERVER-vars.sh

  $MYSQL $MYSQL_ARGS test < $RES/sort-int-bench.sql | tee $RES/sort-int-$SERVER.txt

  echo "TEST_RUN:,$SERVER" >> $RES/summary.txt
  tail -n 10 $RES/sort-int-$SERVER.txt >> $RES/summary.txt
done

cat $RES/summary.txt

