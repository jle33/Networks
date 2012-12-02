//Author: UCM ANDES Lab
#ifndef LISTBUFFER_H
#define LISTBUFFER_H
#include "sendBuffer.h"

typedef sendBuff sendType;
#define BuffAYSIZE 100
#define BUFFMAXNUMVALS BuffAYSIZE

typedef struct Bufflist
{	
	sendType values[BuffAYSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}Bufflist;

void BuffListInit(Bufflist *cur){
	cur->numValues = 0;	
}

bool BuffListPushBack(Bufflist* cur, sendType newVal){
	if(cur->numValues != BUFFMAXNUMVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool BuffListPushFront(Bufflist* cur, sendType newVal){
	if(cur->numValues!= BUFFMAXNUMVALS){
		uint8_t i;
		for( i = cur->numValues-1; i >= 0; --i){
			cur->values[i+1] = cur->values[i];
		}
		cur->values[0] = newVal;
		++cur->numValues;
		return TRUE;	
	}else	return FALSE;
} 

sendType Spop_back(Bufflist* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

sendType Spop_front(Bufflist* cur){
	sendType returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

sendType Sfront(Bufflist* cur)
{
	return cur->values[0];
}

sendType Sback(Bufflist * cur)
{
	return cur->values[cur->numValues-1];	
}

bool BuffListIsEmpty(Bufflist* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t BuffListSize(Bufflist* cur){	return cur->numValues;}

void BuffListClear(Bufflist* cur){	cur->numValues = 0;}

sendType BuffListGet(Bufflist* cur, nx_uint8_t i){	return cur->values[i];}

bool BuffListContains(Bufflist* list, uint8_t SEQ){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		if(SEQ == list->values[i].seq) return TRUE;
	}
	return FALSE;
}

uint8_t NumBuffListContains(Bufflist* list, uint8_t SEQ){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		if(SEQ == list->values[i].seq) return i;
	}
	return -1;
}

#endif /* LISTBUFFER_H */
