#!/bin/bash

LOCALHOST=127.0.0.1
INITIAL_PORT=11211


#if [ "$#" -lt 1 ]
#then
#	echo "Uso: `basename $0` key [ip] [port] (tambien se pueden setear las variables MEM_IP y MEM_PORT)"
#	echo "   (defaults: ip=$LOCALHOST y puerto=$INITIAL_PORT)"
#	exit 1
#fi

test -z "$MEM_IP" && IP_DEFAULT=$LOCALHOST || IP_DEFAULT=$MEM_IP
test -z "$MEM_PORT" && PORT_DEFAULT=$INITIAL_PORT ||  PORT_DEFAULT=$MEM_PORT


test -n "$1" && IP=$1 || IP=$IP_DEFAULT
test -n "$2" && PORT=$2 || PORT=$PORT_DEFAULT


printf "flush_all\r\nquit\r\n" | nc -n $IP $PORT

test $? -ne "0" && echo "Error de coneccion (usando ip:$IP y puerto:$PORT)" && exit 1
