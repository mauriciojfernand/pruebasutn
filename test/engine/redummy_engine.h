/*
 * dummy_engine.c
 *
 *  Created on: 15/03/2012
 *      Author: fviale
 */

#ifndef DUMMY_ENGINE_C_
#define DUMMY_ENGINE_C_

	#include <stdbool.h>
	#include <memcached/engine.h>
	#include <memcached/util.h>
	#include <memcached/visibility.h>


	/*
	 * Esta es una estructura utilizada para almacenar y respresentar un elemento almacenado en la cache
	 */
	typedef struct {
	   void *key;
	   size_t nkey;
	   void *data;
	   size_t ndata;
	   int flags;
	   bool stored;
	   rel_time_t exptime;
	}t_ng_item;


	/*
	 * Esta es la estructura que utilizo para representar el engine, para que memcached pueda manipularla el
	 * primer campo de esta tiene que ser ENGINE_HANDLE_V1 engine; el resto de los campos pueden ser los que querramos
	 */
	typedef struct {
		ENGINE_HANDLE_V1 engine;
		GET_SERVER_API get_server_api;

	}t_quick_ng;


	// Esta funcion es escencial ya que es la que busca memcached para ejecutar cuando levanta la shared library
	MEMCACHED_PUBLIC_API ENGINE_ERROR_CODE create_instance(uint64_t interface, GET_SERVER_API get_server_api, ENGINE_HANDLE **handle);

#endif /* DUMMY_ENGINE_C_ */
