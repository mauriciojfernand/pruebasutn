#include <stdlib.h>
#include <string.h>


// Este include es necesario para que el include <memcached/config_parser.h> no tire error de compilación
#include <stdbool.h>
// Aca estan las tools de memcached para levantar la configuración provista por el usuario en los parametros de ejecución
#include <memcached/config_parser.h>


#include "redummy_engine.h"


/*
 * Estas son las funciones estaticas necesarias para que el engine funcione
 */

static ENGINE_ERROR_CODE dummy_ng_initialize(ENGINE_HANDLE* , const char* config_str);
static void dummy_ng_destroy(ENGINE_HANDLE*, const bool force);

static ENGINE_ERROR_CODE dummy_ng_allocate(ENGINE_HANDLE* , const void* cookie, item **item, const void* key,
											const size_t nkey, const size_t nbytes, const int flags, const rel_time_t exptime);
static bool dummy_ng_get_item_info(ENGINE_HANDLE *, const void *cookie, const item* item, item_info *item_info);
static ENGINE_ERROR_CODE dummy_ng_store(ENGINE_HANDLE* , const void *cookie, item* item, uint64_t *cas,
											ENGINE_STORE_OPERATION operation, uint16_t vbucket);
static void dummy_ng_item_release(ENGINE_HANDLE* , const void *cookie, item* item);
static ENGINE_ERROR_CODE dummy_ng_get(ENGINE_HANDLE* , const void* cookie, item** item, const void* key, const int nkey, uint16_t vbucket);

static ENGINE_ERROR_CODE dummy_ng_flush(ENGINE_HANDLE* , const void* cookie, time_t when);

static ENGINE_ERROR_CODE dummy_ng_item_delete(ENGINE_HANDLE* , const void* cookie, const void* key, const size_t nkey, uint64_t cas, uint16_t vbucket);

/*
 * ************************** Dummy Functions **************************
 *
 * Estas funciones son dummy, son necesarias para que el engine las tengas
 * pero no tienen logica alguna y no seran necesarias implementar
 *
 */

static const engine_info* dummy_ng_get_info(ENGINE_HANDLE* );
static ENGINE_ERROR_CODE dummy_ng_get_stats(ENGINE_HANDLE* , const void* cookie, const char* stat_key, int nkey, ADD_STAT add_stat);
static void dummy_ng_reset_stats(ENGINE_HANDLE* , const void *cookie);
static ENGINE_ERROR_CODE dummy_ng_unknown_command(ENGINE_HANDLE* , const void* cookie, protocol_binary_request_header *request, ADD_RESPONSE response);
static void dummy_ng_item_set_cas(ENGINE_HANDLE *, const void *cookie, item* item, uint64_t val);

/**********************************************************************/





/*
 * Esta es la función que va a llamar memcached para instanciar nuestro engine
 */
MEMCACHED_PUBLIC_API ENGINE_ERROR_CODE create_instance(uint64_t interface, GET_SERVER_API get_server_api, ENGINE_HANDLE **handle) {

	/*
	 * Verify that the interface from the server is one we support. Right now
	 * there is only one interface, so we would accept all of them (and it would
	 * be up to the server to refuse us... I'm adding the test here so you
	 * get the picture..
	 */
	if (interface == 0) {
		return ENGINE_ENOTSUP;
	}

	/*
	 * Allocate memory for the engine descriptor. I'm no big fan of using
	 * global variables, because that might create problems later on if
	 * we later on decide to create multiple instances of the same engine.
	 * Better to be on the safe side from day one...
	 */
	t_quick_ng *engine = calloc(1, sizeof(t_quick_ng));
	if (engine == NULL) {
		return ENGINE_ENOMEM;
	}

	/*
	 * We're going to implement the first version of the engine API, so
	 * we need to inform the memcached core what kind of structure it should
	 * expect
	 */
	engine->engine.interface.interface = 1;

	/*
	 * La API de memcache funciona pasandole a la estructura engine que esta dentro de nuestra
	 * estructura t_dummy_ng los punteros a las funciónes necesarias.
	 */
	engine->engine.initialize = dummy_ng_initialize;
	engine->engine.destroy = dummy_ng_destroy;
	engine->engine.get_info = dummy_ng_get_info;
	engine->engine.allocate = dummy_ng_allocate;
	engine->engine.remove = dummy_ng_item_delete;
	engine->engine.release = dummy_ng_item_release;
	engine->engine.get = dummy_ng_get;
	engine->engine.get_stats = dummy_ng_get_stats;
	engine->engine.reset_stats = dummy_ng_reset_stats;
	engine->engine.store = dummy_ng_store;
	engine->engine.flush = dummy_ng_flush;
	engine->engine.unknown_command = dummy_ng_unknown_command;
	engine->engine.item_set_cas = dummy_ng_item_set_cas;
	engine->engine.get_item_info = dummy_ng_get_item_info;


	engine->get_server_api = get_server_api;

	/*
	 * memcached solo sabe manejar la estructura ENGINE_HANDLE
	 * el cual es el primer campo de nuestro t_dummy_ng
	 * El puntero de engine es igual a &engine->engine
	 *
	 * Retornamos nuestro engine a traves de la variable handler
	 */
	*handle = (ENGINE_HANDLE*) engine;

	/* creo la cache de almacenamiento */



	return ENGINE_SUCCESS;
}

/*
 * Esta función se llama inmediatamente despues del create_instance y sirbe para inicializar
 * la cache.
 */
static ENGINE_ERROR_CODE dummy_ng_initialize(ENGINE_HANDLE* handle, const char* config_str){

	return ENGINE_SUCCESS;
}


/*
 * Esta función es la que se llama cuando el engine es destruido
 */
static void dummy_ng_destroy(ENGINE_HANDLE* handle, const bool force){
	free(handle);
}

/*
 * Esto retorna algo de información la cual se muestra en la consola
 */
static const engine_info* dummy_ng_get_info(ENGINE_HANDLE* handle) {
	static engine_info info = {
	          .description = "Redummy Engine v0.1",
	          .num_features = 0,
	          .features = {
	               [0].feature = ENGINE_FEATURE_LRU,
	               [0].description = "No hay soporte de LRU"
	           }
	};

	return &info;
}

// Esta función es la que se encarga de allocar un item. Este item es la metadata necesaria para almacenar la key
// y el valor. Esta función solo se llama temporalemente antes de hacer, por ejemplo, un store. Luego del store
// el motor llama a la función release. Es por ello que utilizamos un flag "stored" para saber si el elemento
// allocado realmente fue almacenado en la cache o no.
// Puede ocurrir que este mismo se llame 2 veces para la misma operación. Esto es porque el protocolo ASCII de
// memcached hace el envio de la información en 2 partes, una con la key, size y metadata y otra parte con la data en si.
// Por lo que es posible que una vez se llame para hacer un allocamiento temporal del item y luego se llame otra vez, la cual
// si va a ser almacenada.
static ENGINE_ERROR_CODE dummy_ng_allocate(ENGINE_HANDLE *handler, const void* cookie, item **item, const void* key,
											const size_t nkey, const size_t nbytes, const int flags, const rel_time_t exptime){

	t_ng_item *it =  malloc( sizeof(t_ng_item) );


	it->flags = flags;
	it->exptime = exptime;
	it->nkey = nkey;
	it->ndata = nbytes;
	it->key = malloc(nkey);
	it->data = malloc(nbytes);
	it->stored = false;

	memcpy(it->key, key, nkey);
	*item = it;

	return ENGINE_SUCCESS;
}


static void dummy_ng_item_release(ENGINE_HANDLE *handler, const void *cookie, item* item){
	t_ng_item *it = (t_ng_item*)item;


	free(it->key);
	free(it->data);
	free(it);

}


static bool dummy_ng_get_item_info(ENGINE_HANDLE *handler, const void *cookie, const item* item, item_info *item_info){
	// casteamos de item*, el cual es la forma generica en la cual memcached trata a nuestro tipo de item, al tipo
	// correspondiente que nosotros utilizamos
	t_ng_item *it = (t_ng_item*)item;

	if (item_info->nvalue < 1) {
	  return false;
	}

	item_info->cas = 0; 		/* Not supported */
	item_info->clsid = 0; 		/* Not supported */
	item_info->exptime = it->exptime;
	item_info->flags = it->flags;
	item_info->key = it->key;
	item_info->nkey = it->nkey;
	item_info->nbytes = it->ndata; 	/* Total length of the items data */
	item_info->nvalue = 1; 			/* Number of fragments used ( Default ) */
	item_info->value[0].iov_base = it->data; /* Hacemos apuntar item_info al comienzo de la info */
	item_info->value[0].iov_len = it->ndata; /* Le seteamos al item_info el tamaño de la información */

	return true;
}


static ENGINE_ERROR_CODE dummy_ng_get(ENGINE_HANDLE *handle, const void* cookie, item** item, const void* key, const int nkey, uint16_t vbucket){



		return ENGINE_NOT_STORED;

}


static ENGINE_ERROR_CODE dummy_ng_store(ENGINE_HANDLE *handle, const void *cookie, item* item, uint64_t *cas, ENGINE_STORE_OPERATION operation, uint16_t vbucket){

   return ENGINE_SUCCESS;
}

/*
 * Esta función se llama cuando memcached recibe un flush_all
 */
static ENGINE_ERROR_CODE dummy_ng_flush(ENGINE_HANDLE* handle, const void* cookie, time_t when) {

	return ENGINE_SUCCESS;
}

/*
 * Esta función se llama cuando memcached recibe un delete
 */
static ENGINE_ERROR_CODE dummy_ng_item_delete(ENGINE_HANDLE* handle, const void* cookie, const void* key, const size_t nkey, uint64_t cas, uint16_t vbucket) {

	return ENGINE_SUCCESS;
}

/*
 * ************************************* Funciones Dummy *************************************
 */

static ENGINE_ERROR_CODE dummy_ng_get_stats(ENGINE_HANDLE* handle, const void* cookie, const char* stat_key, int nkey, ADD_STAT add_stat) {
	return ENGINE_SUCCESS;
}

static void dummy_ng_reset_stats(ENGINE_HANDLE* handle, const void *cookie) {

}

static ENGINE_ERROR_CODE dummy_ng_unknown_command(ENGINE_HANDLE* handle, const void* cookie, protocol_binary_request_header *request, ADD_RESPONSE response) {
	return ENGINE_ENOTSUP;
}

static void dummy_ng_item_set_cas(ENGINE_HANDLE *handle, const void *cookie, item* item, uint64_t val) {

}


