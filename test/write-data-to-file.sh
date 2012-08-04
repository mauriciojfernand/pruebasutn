#!/bin/bash

source util_char.sh


if [ "$#" -lt "4" ]
then
	echo "Uso: `basename $0` nombreArchivo bufferSize bufferOffset bufferCount [zeroed|random|char] (offset=eof para agregar al final, zeroed type es el default)"
	exit 1
fi

TO=$1
BUFFER=$2
SEEK=$3
COUNT=$4
TYPE=$5



if [ -z "$TYPE" ]
then
        TYPE=zeroed
        echo "== Setting \"$TYPE\" type by default =="
fi

case $TYPE in

random)
        FROM=/dev/urandom
        ;;
zeroed)
        FROM=/dev/zero
        ;;
char)
	let "BYTES_COUNT=$COUNT*$BUFFER"
	TEMP_FILE=file-$RANDOM.temp
        write_char a $BYTES_COUNT $TEMP_FILE
	FROM=$TEMP_FILE
        ;;
*)
        echo Tipo de contenido \"$TYPE\" invalido!
        exit 1
        ;;
esac



if [ ! -e $TO ]
then
	echo "== Warning! El archivo \"$TO\" no existe y sera creado! =="
fi

if [ "$SEEK" == "eof" ]
then
	WHERE="oflag=append"
else
	WHERE="seek=$SEEK"
fi


dd if=$FROM of=$TO bs=$BUFFER count=$COUNT conv=notrunc,fsync $WHERE


rm -f $TEMP_FILE

