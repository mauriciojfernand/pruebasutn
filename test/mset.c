/*
 * mset.c
 *
 *  Created on: 13/07/2012
 *      Author: pc
 */

#include <libmemcached/memcached.h>
#include<libmemcached/memcached_util.h>
#include <stdio.h>
#include <string.h>
#include "utilarg.c"

int main(int argc, char *argv[]){

	int puerto = 11211;
	char localhost[] = "127.0.0.1";
	char *stringValue, *ip, *key;
	memcached_st *st;
	memcached_return_t error;

	ip = localhost;
	if(argc<3){
		printf("Uso %s key stringValue [ip] [port] \n", argv[0]);
		print_defaults(ip, puerto);
		exit(1);
	}

	key = argv[1];
	stringValue = argv[2];

	fill_ip_and_port(&ip, &puerto, argv[3], argv[4], argc - 3);

	st = memcached_create(NULL);
	
	set_mode(st);

	memcached_server_add(st, ip, puerto);

	error = memcached_set(st, key, strlen(key), stringValue, strlen(stringValue), 0, 0);
	if(error == MEMCACHED_SUCCESS)  printf("STORED\n");
		else printf("%s\n", memcached_strerror(st, error));



	memcached_free(st);

	return 0;
}



