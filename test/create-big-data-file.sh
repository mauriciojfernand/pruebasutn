#!/bin/bash


if [ "$#" -lt "2" ]
then
	echo "Uso: `basename $0` nombreArchivo sizeInBytes [random|zeroed] (random es el default)"
	echo "Nota: Sirve para crear archivos binarios grandes (mas de 10mb) mas rapido, pero depende de que el *truncate* funcione bien"
	exit 1
fi

FROM=/dev/urandom
TO=$1
QTY=$2
TYPE=$3

let "BUFFER_SIZE=32*1024"
let "B_QTY=($QTY/$BUFFER_SIZE) + 1"
 

if [ -z "$TYPE" ]
then
	echo "Setting random type by default"
	TYPE=random
fi

if [ -e $TO ]
then
	echo "El archivo \"$TO\" ya existe! "
	exit 1
fi

case $TYPE in

random)
	dd if=/dev/urandom of=$TO bs=$BUFFER_SIZE count=$B_QTY 
	truncate -s $QTY $TO
	echo "File \"$TO\" truncated to $QTY"
	;;
zeroed)
	dd if=/dev/zero of=$TO bs=$BUFFER_SIZE count=$B_QTY
	truncate -s $QTY $TO
	echo "File \"$TO\" truncated to $QTY"
	;;
*)
	echo Tipo de contenido \"$TYPE\" invalido!
	exit 1
	;;
esac


