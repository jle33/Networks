//Author: UCM ANDES Lab
//Date: 2/16/2012
//Description: A simple hashtable. Change the HASHMAP_TYPE to change the type being stored.
//Modified for use as a BUFFER 11/15/2012
#ifndef SOCKETBUFFHASHMAP_H
#define SOCKETBUFFHASHMAP_H
#include "transport.h"
	
typedef transport TransType;

enum{
	TRANS_MAX_SIZE = 15
};

typedef struct TransEntry{
	uint16_t key;
	TransType value;
}TransEntry;

typedef struct transmap{
	TransEntry map[TRANS_MAX_SIZE];
	uint8_t keys[TRANS_MAX_SIZE];
	uint8_t numofVals;
}transmap;

/*
 * trans, Hash2
 * @param int k = key
 * @return int - uses a hashing function to create a position.
 */
uint16_t transhash(uint16_t k){
	return k%13;
}
uint16_t transhash2(uint16_t k){
	return 1+k%11;
}

/*
 * Hash3
 * @param 	uint16_t k = key
 * 			uint16_t i = number of iterations.
 * @return 	uint16_t a function that return as position based on hash and hash2.
 */
uint16_t transhash3(uint16_t k, uint16_t i){
 	return (transhash(k)+ i*transhash2(k))%TRANS_MAX_SIZE;
 }

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 */
void transmapInit(transmap *input){
	uint16_t i;
	for(i=0; i<TRANS_MAX_SIZE; i++){
		input->map[i].key=0; 		
	}
	input->numofVals=0;
}

bool transmapIsEmpty(transmap *input){
	if(input->numofVals==0)return TRUE;
	return FALSE;
}

/*
 * hashmapGet - return value with the inputed key.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
TransType transmapGet(transmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=transhash3(key, i);
		if(input->map[j].key == key){	return input->map[j].value;}
		i++;
	}while(i<TRANS_MAX_SIZE);	
	return input->map[input->keys[0]].value;
}

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
bool transmapContains(transmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	dbg("hashmap", "Checking to see if values exist\n");
	do{
		j=transhash3(key, i);
		if(input->map[j].key == key){	return TRUE;}
		i++;
	}while(i<TRANS_MAX_SIZE);	
	return FALSE;
}


/*
 * hashmapInsert - insert in a free position based on the value. If it exist already, overwrite the value.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 * 			TransType value = the value to be stored
 */
void transmapInsert(transmap *input, uint8_t key, TransType value){
	uint16_t i=0;	uint16_t j=0;
	dbg("transmap", "Attempting to place Entry: %hhu\n", key);
	do{
		j=transhash3(key, i);
		if(input->map[j].key==0 || input->map[j].key==key){
			if(input->map[j].key==0){
				input->keys[input->numofVals]=key;
				input->numofVals++;
			}
			input->map[j].value=value;
			input->map[j].key = key;
			dbg("transmap","------------------Entry: %hhu was placed in %hhu\n", key, j);
			return;
		}
		i++;
	}while(i<TRANS_MAX_SIZE);
	
}

/*
 * hashmapRemove - removes value stored in the array, also removes key from known values.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
void transmapRemove(transmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=transhash3(key, i);
		if(input->map[j].key == key){	input->map[j].key=0; return;}
		i++;
	}while(i<TRANS_MAX_SIZE);
	
	for(i=0; i<input->numofVals; i++){
		if(input->keys[i]==key){
			for(j=i; j<input->numofVals-1; j++){
				input->keys[j]=input->keys[j+1];
			}
			input->numofVals--;
			return;
		}
	}
}

#endif /* SOCKETBUFFHASHMAP_H */
