#!/bin/bash

source util_char.sh


if [ "$#" -lt "2" ]
then
	echo "Uso: `basename $0` nombreArchivo sizeInBytes [random|zeroed|char] (random es el default)"
	exit 1
fi

FROM=/dev/urandom
TO=$1
QTY=$2
TYPE=$3

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
	dd if=/dev/urandom of=$TO bs=1 count=$QTY 
	;;
zeroed)
	dd if=/dev/zero of=$TO bs=1 count=$QTY
	;;
char)
	write_char_file a $QTY $TO
	stat $TO | head -2
	;;
*)
	echo Tipo de contenido \"$TYPE\" invalido!
	exit 1
	;;
esac


