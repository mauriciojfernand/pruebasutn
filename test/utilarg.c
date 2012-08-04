int fill_ip_and_port(char** ip, int * puerto, char * ip_arg, char * port_arg, int argc){
        // Leyendo valores del entorno
        if (getenv("MEM_IP") != NULL){
                *ip = getenv("MEM_IP");
        }

        if (getenv("MEM_PORT") != NULL){
                *puerto = atoi(getenv("MEM_PORT"));
        }

        // Leyendo valores por parametro (que pisan a los del entorno)
        if(argc > 0){
                *ip = ip_arg;
                if(argc > 1) {
                        *puerto = atoi(port_arg);
                }
        }
}

void set_mode(memcached_st *st){
	if (getenv("MEM_MODE") == NULL || strcmp(getenv("MEM_MODE"), "ASCII") != 0){
		puts("<Usando protocolo binario>");
		 memcached_behavior_set(st, MEMCACHED_BEHAVIOR_BINARY_PROTOCOL, 1);
	} else {
		puts("<Usando protoclo ASCII>");
	}
}
void print_defaults(char * ip, int puerto){
	printf("Defaults: ip = %s, port = %d, modo = binario\nSe pueden setear las variables de entorno MEM_IP, MEM_PORT y MEM_MODE, donde para este ultimo cualquier valor distinto de ASCII sera considerado como modo binario)\n", ip, puerto);
}
