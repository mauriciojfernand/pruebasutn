/*
 * mget_from_file.c
 *
 *  Created on: 13/07/2012
 *      Author: pc
 */

#include <libmemcached/memcached.h>
#include<libmemcached/memcached_util.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#include "utilarg.c"

int main(int argc, char *argv[]){

	int puerto = 11211;
	char localhost[] = "127.0.0.1";
	char *path, *ip, *key, *buffer;
	memcached_st *st;
	uint32_t flag;
	size_t size;
	FILE *fp;
	memcached_return_t error;

	ip = localhost;
	if(argc<3){
		printf("Uso %s key filename [ip] [port]\n", argv[0]);
		print_defaults(ip, puerto);
		exit(1);
	}

	key = argv[1];
	path = argv[2];

	fill_ip_and_port(&ip, &puerto, argv[3], argv[4], argc - 3);	

	st = memcached_create(NULL);
	
	set_mode(st);	
        
	
	memcached_server_add(st, ip, puerto);


	buffer = memcached_get(st, key, strlen(key), &size, &flag, &error);
	if(buffer == NULL){
		printf("%s\n", memcached_strerror(st, error));
		memcached_free(st);
		return -1;
	}



	fp = fopen(path, "w");
	if(fp==NULL){
		perror("fopen");
		exit(1);
	}


	fwrite(buffer, size, 1, fp);
	fclose(fp);




	free(buffer);
	memcached_free(st);

	return 0;
}


