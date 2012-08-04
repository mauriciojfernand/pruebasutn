#!/bin/bash

function print_init(){
	printf "$1... "
}

function test_result (){
	test "$?" -ne "0" && echo $FAIL_MSG && exit 1 || echo DONE
}


function create_ext2_disk(){
	local DISK_FILE=$1
	local DISK_SIZE_IN_BLOCKS=$2
	local BLOCK_SIZE=$3

	test -a $DISK_FILE && echo "El archivo $DISK_FILE ya existe!" >> $LOG && return 1

	touch $DISK_FILE
	
	mkfs.ext2 -F -O none,sparse_super -b $BLOCK_SIZE $DISK_FILE $DISK_SIZE_IN_BLOCKS -I 128 &>> $LOG
}

function mount_fs(){
	local DEV=$1
	local MNT=$2
	mount -o loop $DEV $MNT
}

function md5sum_recursive(){
	local DIR=$1
	local OUT=$2
	find  mnt -type f | xargs md5sum > $OUT
}

function make_disk_1(){
# ========= 1kb-3mb.disk ========
	local DISK=$DISKS_DIR/$1

	print_init "Creando disco \"$DISK\""
	create_ext2_disk $DISK 3000 1024
	test_result

	print_init "Montando disco \"$DISK\""
	mount_fs $DISK $MNT_DIR
	test_result

	print_init "Creando directorios"
	mkdir -pv $MNT_DIR/dir1/dir2/dir3/dir4 &>>$LOG
	test_result

	print_init "Creando archivos comunes"
	echo hola  > $MNT_DIR/dir1/dir2/dir3/hola.txt && echo hola  > $MNT_DIR/dir1/dir2/hola.txt && echo hola  > $MNT_DIR/dir1/hola.txt && touch $MNT_DIR/a.txt $MNT_DIR/b.txt $MNT_DIR/c.txt
	test_result

	print_init "Creando archivo con direccion simple"
	./create-data-file.sh $MNT_DIR/directo.bin 12287 random &>>$LOG
	test_result

	print_init "Creando archivo con indireccion simple"
	./create-data-file.sh $MNT_DIR/indirecto-simple.bin 262143 random &>>$LOG
	test_result

	print_init "Copiando indirecto-simple.bin a otro-indirecto-simple.bin"
	cp -v $MNT_DIR/indirecto-simple.bin $MNT_DIR/otro-indirecto-simple.bin &>>$LOG
	test_result

	print_init "Calculando md5sums"
	md5sum_recursive $MNT_DIR $DISKS_DIR/"`basename $DISK .disk`".md5sum
	test_result

	print_init "Cambiando permisos"
	chown -Rv utnso:utnso $MNT_DIR &>>$LOG
	test_result

	#ls -lR $MNT_DIR

	print_init "Desmontando \"$DISK\""
	umount $MNT_DIR
	test_result

	#rm $DISK1

	if $COPY_AND_CHANGE # La falta de corchetes no es casualidad
	then
		local M_DISK=$DISKS_DIR/modified_$1
		print_init "Copiando disco \"$DISK\" a \"$M_DISK\""
		cp -v $DISK $M_DISK >> $LOG
		test_result

		print_init "Montando disco \"$M_DISK\""
		mount_fs $M_DISK $MNT_DIR
		test_result

		print_init "Escribiendo data en el archivo directo.bin"
		./write-data-to-file.sh $MNT_DIR/directo.bin 2000 0 1 zeroed &>>$LOG
		test_result

		print_init "Escribiendo data en el archivo indirecto-simple.bin"
		./write-data-to-file.sh $MNT_DIR/indirecto-simple.bin 4000 52 1 zeroed &>>$LOG
		test_result

		print_init "Escribiendo data en el archivo otro-indirecto-simple.bin"
		./write-data-to-file.sh $MNT_DIR/otro-indirecto-simple.bin 3000 eof 1 zeroed &>>$LOG
		test_result

		print_init "Calculando md5sums"
		md5sum_recursive $MNT_DIR $DISKS_DIR/"`basename $M_DISK .disk`".md5sum
		test_result

		print_init "Desmontando \"$M_DISK\""
		umount $MNT_DIR
		test_result

	fi

	# ==============================
	final_stuff
}

function make_disk_2(){
	# ========== 1kb-300mb.disk =======

	local DISK=$DISKS_DIR/$1

	print_init "Creando disco \"$DISK\""
	create_ext2_disk $DISK 307200 1024
	test_result

	print_init "Montando disco \"$DISK\""
	mount_fs $DISK $MNT_DIR
	test_result

	print_init "Creando archivo con indireccion doble (paciencia)"
	./create-big-data-file.sh $MNT_DIR/indirecto-doble.bin 67383000 random &>>$LOG
	test_result

	print_init "Creando archivo con indireccion triple (mas paciencia)"
	./create-big-data-file.sh $MNT_DIR/indirecto-triple.bin 157286400 random &>>$LOG
	test_result

	print_init "Calculando md5sums"
	md5sum_recursive $MNT_DIR $DISKS_DIR/"`basename $DISK .disk`".md5sum
	test_result

	print_init "Cambiando permisos archivos"
	chown -Rv utnso:utnso $MNT_DIR &>>$LOG
	test_result

	#ls -lR $MNT_DIR

	print_init "Desmontando \"$DISK\""
	umount $MNT_DIR
	test_result


	if $COPY_AND_CHANGE # La falta de corchetes no es casualidad
	then
		local M_DISK=$DISKS_DIR/modified_$1
		print_init "Copiando disco \"$DISK\" a \"$M_DISK\""
		cp -v $DISK $M_DISK >> $LOG
		test_result

		print_init "Montando disco \"$M_DISK\""
		mount_fs $M_DISK $MNT_DIR
		test_result

		print_init "Escribiendo data en el archivo indirecto-doble.bin"
		./write-data-to-file.sh $MNT_DIR/indirecto-doble.bin 1 60000000 1 &>>$LOG
		test_result

		print_init "Escribiendo data en el archivo indirecto-triple.bin (aca no mas paciencia)"
		./write-data-to-file.sh $MNT_DIR/indirecto-triple.bin 32768 4785 1408 &>>$LOG
		test_result

		print_init "Calculando md5sums"
		md5sum_recursive $MNT_DIR $DISKS_DIR/"`basename $M_DISK .disk`".md5sum
		test_result

		print_init "Desmontando \"$M_DISK\""
		umount $MNT_DIR
		test_result

	fi



	# ===============================
	final_stuff
}

function make_disk_3(){
	# ========== 2kb-100mb.disk =======

	local DISK=$DISKS_DIR/$1

	print_init "Creando disco \"$DISK\""
	create_ext2_disk $DISK 51200 2048
	test_result

	print_init "Montando disco \"$DISK\""
	mount_fs $DISK $MNT_DIR
	test_result

	print_init "Cambiando permisos archivos"
	chown -Rv utnso:utnso $MNT_DIR &>>$LOG
	test_result

	#ls -lR $MNT_DIR

	print_init "Desmontando \"$DISK\""
	umount $MNT_DIR
	test_result

	# ===============================
	final_stuff
}

function make_disk_4(){
	# ========== 4kb-400mb.disk =======

	local DISK=$DISKS_DIR/$1

	print_init "Creando disco \"$DISK\""
	create_ext2_disk $DISK 102400 4096
	test_result

	print_init "Montando disco \"$DISK\""
	mount_fs $DISK $MNT_DIR
	test_result

	print_init "Cambiando permisos archivos"
	chown -Rv utnso:utnso $MNT_DIR &>>$LOG
	test_result

	#ls -lR $MNT_DIR

	print_init "Desmontando \"$DISK\""
	umount $MNT_DIR
	test_result

	# ===============================
	final_stuff
}




function final_stuff(){
	print_init "Cambiando permisos discos"
	chown -Rv utnso:utnso $DISKS_DIR &>>$LOG
	test_result

	print_init "Cambiando permisos log"
	chown -Rv utnso:utnso $LOG &>>$LOG
	test_result
}


function create_backups(){
	local DIR=$1
	print_init "Backupeando discos"
	find $DIR -name "*.disk" | while read FILENAME; do cp -v $FILENAME $FILENAME.backup &>>$LOG && chown -v utnso:utnso $FILENAME.backup &>>$LOG; done
	test_result
}

# =================================================================================================================
# =========================================== INICIO SCRIPT =======================================================
# =================================================================================================================

echo -e "\n===== Inicio script =====\n"

test "`whoami`" != "root" && echo Ejecutar el script con sudo! && exit 1


LOG="`basename $0 .sh`.log"
#LOG="`basename $0 .sh`_`date +%s`.log"
FAIL_MSG="FAIL (check \"$LOG\" for details)"

# Vaciamos el archivo log si ya existia
>$LOG

DISKS_DIR=disks
MNT_DIR=mnt

DISK1_NAME=1kb-3mb.disk
DISK2_NAME=1kb-300mb.disk
DISK3_NAME=2kb-100mb.disk
DISK4_NAME=4kb-400mb.disk

TARGET=$1

test "$2" == "nd" && COPY_AND_CHANGE=false || COPY_AND_CHANGE=true

case $TARGET in

$DISK1_NAME)
	make_disk_1 $DISK1_NAME
	create_backups $DISKS_DIR
	;;
$DISK2_NAME)
	make_disk_2 $DISK2_NAME
	create_backups $DISKS_DIR
	;;
$DISK3_NAME)
	make_disk_3 $DISK3_NAME
	create_backups $DISKS_DIR
	;;
$DISK4_NAME)
	make_disk_4 $DISK4_NAME
	create_backups $DISKS_DIR
	;;

all)
	make_disk_1 $DISK1_NAME
	make_disk_2 $DISK2_NAME
	make_disk_3 $DISK3_NAME
	make_disk_4 $DISK4_NAME
	create_backups $DISKS_DIR
	;;
rm)
	printf "Esta seguro? (s/n):"
	read RESPONSE
	test "$RESPONSE" != "s" && echo "Cancelado!" && exit 1

	umount -rv $MNT_DIR 2>/dev/null
	rm -fv $DISKS_DIR/*
	rm -fv $LOG
	;;
*)
	echo "Target no ingresado o invalido"
	echo "Uso: `basename $0` [$DISK1_NAME|$DISK2_NAME|$DISK3_NAME|$DISK4_NAME|all|rm] [nd]"
	;;
esac


echo -e "\n===== Fin del script ====="
