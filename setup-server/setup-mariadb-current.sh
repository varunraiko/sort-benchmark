#!/bin/bash

set -e


if [ "x${1}y" == "xy" ] ; then 
  echo "Usage: $0 BRANCH_NAME [revision  [directory_name] ]"
  exit 1
fi

BRANCH="${1}"
REVISION="${2}"
DIRNAME="${3}"

if [ "x${DIRNAME}y" == "xy" ] ; then 
  DIRNAME=mariadb-$BRANCH
fi

HOMEDIR=`pwd`
DATADIR="$HOMEDIR/$DIRNAME-data"

if [ -d $DATADIR ] ; then
  echo "Data directory $DATADIR exists, will not overwrite it "
  du -hs $DATADIR
  exit 1;
fi

# --single-branch
git clone --branch $BRANCH  https://github.com/MariaDB/server.git  $DIRNAME


(
cd $DIRNAME

if [ "x${REVISION}y" != "xy" ] ; then
  git reset --hard $REVISION
fi

git submodule init
git submodule update
cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DWITHOUT_MROONGA:bool=1 -DWITHOUT_TOKUDB:bool=1
make -j8
cd .. 
)

(
  cd $DIRNAME/mysql-test
  ./mtr alias
  cp -r var/install.db $DATADIR
  cp -r var/install.db $DATADIR.clean
)

# Guess a reasonable socket name
source_dir=`pwd`
socket_name="`basename $source_dir`.sock"
SOCKETNAME="/tmp/$socket_name"


# plugin-load=ha_rocksdb.so
# default-storage-engine=rocksdb
# skip-innodb
# default-tmp-storage-engine=MyISAM
# skip-slave-start
# log-bin=pslp
# binlog-format=row

cat > $HOMEDIR/my-$DIRNAME.cnf << EOF
[mysqld]

bind-address=0.0.0.0
datadir=$DATADIR
plugin-dir=$HOMEDIR/$DIRNAME/mysql-test/var/plugins

log-error
lc_messages_dir=$HOMEDIR/$DIRNAME/sql/share

tmpdir=/tmp
port=3341
socket=$SOCKETNAME
gdb
server-id=12

innodb_buffer_pool_size=8G

EOF

cat > mysql-vars.sh <<EOF
MYSQL="`pwd`/$DIRNAME/client/mysql"
MYSQLSLAP="`pwd`/$DIRNAME/client/mysqlslap"
MYSQL_SOCKET="--socket=$SOCKETNAME"
MYSQL_USER="-uroot"
MYSQL_ARGS="\$MYSQL_USER \$MYSQL_SOCKET"
EOF

source mysql-vars.sh
cp mysql-vars.sh $DIRNAME-vars.sh

(
cd $HOMEDIR/$DIRNAME/sql
../sql/mysqld --defaults-file=$HOMEDIR/my-$DIRNAME.cnf &
)


client_attempts=0
while true ; do
  echo $MYSQL $MYSQL_ARGS -e "select version()";
  $MYSQL $MYSQL_ARGS -e "select version()";

  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1

  client_attempts=$((client_attempts + 1))
  if [ $client_attempts -ge 30 ]; then
    echo "Failed to start server."
    exit 1
  fi
done

echo "Done setting up MariaDB"

