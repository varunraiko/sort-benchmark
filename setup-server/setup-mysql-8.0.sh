#!/bin/bash

HOMEDIR=`pwd`

BRANCH=8.0
SERVER_VERSION=8.0
DIRNAME="mysql-$SERVER_VERSION"

git clone --branch $BRANCH --depth 1 https://github.com/mysql/mysql-server.git $DIRNAME

cd mysql-$SERVER_VERSION
cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDOWNLOAD_BOOST=1 -DWITH_BOOST=$HOMEDIR/mysql-boost \
 -DENABLE_DOWNLOADS=1 -DFORCE_INSOURCE_BUILD=1 -DWITH_UNIT_TESTS=0

make -j8

cd mysql-test
perl ./mysql-test-run alias
cp -r var/data $HOMEDIR/$DIRNAME-data
cp -r var/data $HOMEDIR/$DIRNAME-data.clean
cd ..


source_dir=`pwd`
socket_name="`basename $source_dir`.sock"
SOCKETNAME="/tmp/$socket_name"

cat > $HOMEDIR/my-$DIRNAME.cnf <<EOF

[mysqld]
datadir=$HOMEDIR/$DIRNAME-data

tmpdir=/tmp
port=3320
socket=$SOCKETNAME
#binlog-format=row
gdb
lc_messages_dir=../share
server-id=12
bind-address=0.0.0.0
log-error
secure_file_priv=
innodb_buffer_pool_size=4G
EOF

cat > $DIRNAME-vars.sh <<EOF
MYSQL="`pwd`/$DIRNAME/bin/mysql"
MYSQLD="`pwd`/$DIRNAME/bin/mysqld"
MYSQLSLAP="`pwd`/$DIRNAME/bin/mysqlslap"
MYSQL_SOCKET="--socket=$SOCKETNAME"
MYSQL_USER="-uroot"
MYSQL_ARGS="\$MYSQL_USER \$MYSQL_SOCKET"
EOF

source $DIRNAME-vars.sh

$MYSQLD --defaults-file=$HOMEDIR/my-$DIRNAME.cnf &

