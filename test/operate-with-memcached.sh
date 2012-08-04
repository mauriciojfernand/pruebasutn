#!/bin/bash

function ntochar() {
  [ ${1} -lt 256 ] || return 1
  printf \\$(printf '%03o' $1)
}

function limited_random(){
	local LIMIT=$1
	let "RESULT=$RANDOM%$LIMIT"
	printf $RESULT
}


function random_char(){
	local LIMIT=$1
	local NUMBER=`limited_random $LIMIT`
	let "NUMBER+=65" # Arrancamos desde la 'A'
	ntochar $NUMBER
}

function grow_to_n(){
	local CHAR=$1
	local N=0
	let "N=$2-1"
	local RESULT=$CHAR

	for i in $(seq 1 $N)
	do
		RESULT=${CHAR}${RESULT}
	done
	printf $RESULT
}


arr_limit=10

INITIAL_KEYS=""
for i in $(seq 1 $arr_limit)
do
	INITIAL_KEYS="${INITIAL_KEYS} KEY_NOT_STORED-$i"
done

arr=($INITIAL_KEYS)


function arr_add_first() {
  arr=("$1" "${arr[@]}")
}

arr_drop_last() {
  i=$(expr ${#arr[@]} - 1)
  #placeholder=${arr[$i]}
  unset arr[$i]
  arr=("${arr[@]}")
}

function arr_shift() {
	arr_drop_last
	arr_add_first $1
}

function arr_get_random_value(){
	local R=`limited_random $arr_limit`
	printf "${arr[$R]}"
}


function store_random_value(){
	local CHAR_UNIVERSE_SIZE=$1
	local VALUE_MAX_SIZE=$2

	local KEY=key
	local RANDOM_CHAR=`random_char $CHAR_UNIVERSE_SIZE`
	local LENGTH=`limited_random VALUE_MAX_SIZE`
	let "LENGTH++"

	KEY=${KEY}-${RANDOM_CHAR}_${LENGTH}

	VALUE=`grow_to_n $RANDOM_CHAR $LENGTH`

	echo "[$THREAD_ID] - Almacenando key:$KEY value:$VALUE"

	./mset $KEY $VALUE 

	arr_shift $KEY
}

function get_stored_value(){
	local KEY=`arr_get_random_value`
	echo "[$THREAD_ID] - Obteniendo key:$KEY"
	./mget $KEY
}

function del_stored_value(){
	local KEY=`arr_get_random_value`
	echo "[$THREAD_ID] - Borrando key:$KEY"
	./mdelete.sh $KEY
}


# ======================================================= INICIO =====================================================

if [ "$#" -lt 4 ]
then
	echo "Uso: `basename $0` charUniverseSize valueMaxSize sleepInterval iterations [thread-id]"
	echo "  (Nota: Para charUniverseSize: un valor como 3, implica el universo: A,B,C. Valores chicos favorecen la ocurrencia de repetidos)"
	echo "  (Nota: ip y puerto para memcached van por las variables de entorno MEM_IP y MEM_PORT"
	exit 1
fi

# Valores chicos favorece la ocurrencia de repetidos
CHAR_UNIVERSE_SIZE=$1 # Un valor como 3 implica un universo de A,B,C
VALUE_MAX_SIZE=$2
SLEEP_INTERVAL=$3
ITERATIONS=$4
THREAD_ID=$5


for i in $(seq 1 $ITERATIONS)
do
	store_random_value $CHAR_UNIVERSE_SIZE $VALUE_MAX_SIZE

	get_stored_value

	del_stored_value

	sleep $SLEEP_INTERVAL
done

echo "Fin $THREAD_ID"

