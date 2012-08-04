#!/bin/bash

if [ "$#" -lt "3" ]
then
        echo "Uso: `basename $0` nombreArchivo cantidadDeLecturas intervaloEnSegundos"
	echo "Nota: en el intervalo, un valor como 0.5 duerme aproximadamente medio segundo"
        exit 1
fi



FILE=$1
TIMES=$2
INTERVAL=$3

for i in $(seq 1 $TIMES)
do
	sleep $INTERVAL
	md5sum $FILE
done
