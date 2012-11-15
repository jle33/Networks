/*
 * Author: UCM ANDES Lab
 * Description: A simple method of converting the hashmap class I created into an iterator.
 */
#ifndef BUFFERITERATOR_H
#define BUFFERITERATOR_H

#include "SocketBuffhashmap.h"

typedef struct transiterator{
	TransType values[TRANS_MAX_SIZE];
	uint16_t size;
	uint16_t position;
} transiterator;

/*
 * iteratorInit - copies values from the transmap to the iterator struct.
 * @param
 * 			iterator *it = iterator that is to be made.
 * 			transmap *input = transmap from which the values are made from.
 */
void transiteratorInit(transiterator *it, transmap *input){
	uint16_t i;
	it->position = 0;
	it->size = 0;
		
	for(i=0; i<input->numofVals; i++){
		it->values[i] = transmapGet(input, input->keys[i]);
		it->size++;
	}
}

/*
 * iteratorNext - returns the next value.
 * @param
 * 			iterator *it = iterator that the value is getting from.
 */
TransType transiteratorNext(transiterator *it){
	if(it->position < it->size){
		TransType temp=it->values[it->position];
		it->position++;
		return temp;
	}
	it->position++;
	dbg("iterator", "Error: iterator has overflown.");
	return it->values[0];
}

void transiteratorResetPos(transiterator * it) {
	it->position = 0;
}

/*
 * routeIteratorNext - returns a bool if the iterator has a next value.
 * @param
 * 			iterator *it = iterator that the value is getting from.
 * @return
 * 			bool = returns TRUE if there is another value else returns FALSE.
 */
bool transiteratorHasNext(transiterator * it) {
	dbg("iterator", "it Position: %hhu \nit Size: %hhu\n", it->position, it->size);
			if(it->position < it->size) 
		return TRUE;
	return FALSE;
}
#endif /* BUFFERITERATOR_H */