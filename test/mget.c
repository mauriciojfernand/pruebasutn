/*
 * mget.c
 *
 *  Created on: 13/07/2012
 *      Author: pc
 */
#include <libmemcached/memcached.h>
#include<libmemcached/memcached_util.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "utilarg.c"

int main(int argc, char *argv[]){

	int puerto = 11211;
	char localhost[] = "127.0.0.1";
	char *ip, *key, *stringValue;
	memcached_st *st;
	uint32_t flag;
	size_t size;
	memcached_return_t error;
	ip = localhost;

	if(argc < 2){
		printf("Uso %s key [ip] [port] \n", argv[0]);
		print_defaults(ip, puerto);
		exit(1);
	}

	key = argv[1];

	fill_ip_and_port(&ip, &puerto, argv[2], argv[3], argc - 2);

	st = memcached_create(NULL);


	set_mode(st);

	memcached_server_add(st, ip, puerto);


	stringValue = memcached_get(st, key, strlen(key), &size, &flag, &error);
	if(stringValue == NULL){
		printf("%s\n", memcached_strerror(st, error));
		memcached_free(st);
		return -1;
	}


	printf("%s\n", stringValue);

	free(stringValue);
	memcached_free(st);

	return 0;
}

