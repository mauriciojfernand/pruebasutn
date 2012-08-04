#!/bin/bash


if [ "$#" -lt "1" ]
then
	echo "Uso: `basename $0` disco"
	exit 1
fi


dumpe2fs $1 | grep Free | head -2
