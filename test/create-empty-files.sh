#!/bin/bash

if [ "$#" -ne "2" ]
then
	echo "Uso: `basename $0`  dirDestino cantidadDeArchivosACrear"
	exit 1;
fi

COUNT=0
for i in $(seq 1 $2)
	do 
	touch $1/$i.test; 
	let "$? == 0 ? COUNT++ : true"
	done

echo -e "\nEjecucion Finalizada. $COUNT archivos creados."
