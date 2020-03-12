#!/bin/bash

#
#
# 
usage () {
echo "Usage: $0 [-m] server_name"
echo "  -m - Put datadir on /dev/shm"
}

###
### Parse options
###

while getopts ":pmr" opt; do
  case ${opt} in
    m ) USE_RAMDISK=1
      ;;
    r ) RECOVER=1
      ;;
    \? ) 
	usage;
        exit 1
      ;;
  esac
done
shift $((OPTIND -1))

SERVERNAME=$1

if [ "x${SERVERNAME}y" = "xy" ] ; then
  usage;
  exit 1
fi

if [ ! -d $SERVERNAME ]; then 
  echo "Can't find tree $SERVERNAME."
  exit 1
fi

if [ ! -f $SERVERNAME-vars.sh ]; then 
  echo "Can't find settings file $SERVERNAME-vars.sh."
  exit 1
fi

if [[ $USE_RAMDISK ]] ; then
  echo " Using /dev/shm for data dir"
fi

#############################################################################
### Start the server
killall -9 mysqld
sleep 5

DATA_DIR=$SERVERNAME-data

source ${SERVERNAME}-vars.sh

if [[ $RECOVER ]] ; then
  echo "Recovering the existing datadir" 
else
  echo "Initializing new datadir" 
  rm -rf $DATA_DIR
  if [[ $USE_RAMDISK ]] ; then
    rm -rf /dev/shm/$DATA_DIR
    cp -r ${DATA_DIR}.clean /dev/shm/$DATA_DIR
    ln -s /dev/shm/$DATA_DIR $DATA_DIR
  else
    cp -r ${DATA_DIR}.clean $DATA_DIR
  fi	
fi

#exit 0;
$MYSQLD --defaults-file=./my-${SERVERNAME}.cnf & 


server_attempts=0

while true ; do
  client_attempts=0
  while true ; do
    $MYSQL $MYSQL_ARGS -e "select 1"

    if [ $? -eq 0 ]; then
      break
    fi
    sleep 1

    client_attempts=$((client_attempts + 1))
    if [ $client_attempts -ge 10 ]; then 
      break;
    fi 
  done

  MYSQLD_PID=`ps -C mysqld --no-header | awk '{print $1}'`
  if [[ "a${MYSQLD_PID}b" != "ab" ]] ; then 
    break
  fi

  server_attempts=$((server_attempts + 1))
  if [ $server_attempts -ge 4 ]; then
    echo "Failed to launch mysqld"
    exit 1
  fi 
done

# Done.

