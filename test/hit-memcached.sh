#!/bin/bash


if [ "$#" -lt "5" ]
then
	echo "Uso: `basename $0` cantidadThreads iterationsPerThread sleepIntervalForEachThread valueCharUniverse valueMaxSize [ip] [port]"
	exit 1
fi

THREADS_QTY=$1
ITERATIONS=$2
SLEEP_INTERVAL=$3
CHAR_UNIVERSE_SIZE=$4
VALUE_MAX_SIZE=$5

LOG=`basename $0 .sh`.log

>$LOG

test -n "$6" && export MEM_IP=$6
test -n "$7" && export MEM_PORT=$7

for i in $(seq 1 $THREADS_QTY)
do
	if [ "$SLEEP_INTERVAL" == "random" ]
	then
		let "REAL_SLEEP=$RANDOM%3"
	else
		REAL_SLEEP=$SLEEP_INTERVAL
	fi

	# Uso: operate-with-memcached.sh charUniverseSize valueMaxSize sleepInterval iterations [thread-id]
	./operate-with-memcached.sh $CHAR_UNIVERSE_SIZE $VALUE_MAX_SIZE $REAL_SLEEP $ITERATIONS "thread$i" >> $LOG &
done

echo "Todos los threads iniciados. Opening log now... (ctrl+c para salir)"
sleep 2
tail -f $LOG
