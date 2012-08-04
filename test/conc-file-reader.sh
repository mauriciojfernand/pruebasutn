#!/bin/bash

if [ "$#" -lt "5" ]
then
        echo "Uso: `basename $0` cantidadProcesos nombreArchivo cantidadDeLecturas intervaloEnSegundos archivoLog"
	echo "Nota: en el intervalo, un valor como 0.5 duerme aproximadamente medio segundo"
        exit 1
fi



PROCESSES=$1
FILE=$2
TIMES=$3
INTERVAL=$4
LOG=$5

>$LOG

for i in $(seq 1 $PROCESSES)
do
	./file-reader.sh $FILE $TIMES $INTERVAL >>$LOG & 
done

echo Fin del script. Revisar \"$LOG\" una vez que todos los procesos hayan finalizado
