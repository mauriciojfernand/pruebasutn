#!/bin/bash

function write_char_file(){
        local CHAR=$1
        local COUNT=$2
        local DEST=$3

        #for i in $(seq 1 $COUNT)
	for ((I=0; I<$COUNT; I++))
        do
                echo -n $CHAR >> $DEST
        done
}

