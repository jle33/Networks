//Author: UCM ANDES Lab
#include "dataStructures/addrPort.h"
#ifndef ACCEPTBUFFER_H
#define ACCEPTBUFFER_H

typedef addrPort DataMe;
#define INDEXSIZE 255
#define MAXNUMSIZEVALS INDEXSIZE

typedef struct aPlist
{	
	DataMe values[INDEXSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}aPlist;

void aPListInit(aPlist *cur){
	cur->numValues = 0;	
}

bool aPListPushBack(aPlist* cur, DataMe newVal){
	if(cur->numValues != MAXNUMSIZEVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool aPListPushFront(aPlist* cur, DataMe newVal){
	if(cur->numValues!= MAXNUMSIZEVALS){
		
		uint8_t i;
		
		for( i = cur->numValues-1; i >= 0; --i){
			cur->values[i+1] = cur->values[i];
		}
		cur->values[0] = newVal;
		++cur->numValues;
		return TRUE;	
	}else	return FALSE;
} 

DataMe aPpop_back(aPlist* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

DataMe aPpop_front(aPlist* cur){
	DataMe returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

DataMe aPfront(aPlist* cur)
{
	return cur->values[0];
}

DataMe aPback(aPlist * cur)
{
	return cur->values[cur->numValues-1];	
}

bool aPListIsEmpty(aPlist* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t aPListSize(aPlist* cur){	return cur->numValues;}

void aPListClear(aPlist* cur){	cur->numValues = 0;}

DataMe aPListGet(aPlist* cur, nx_uint8_t i){	return cur->values[i];}

bool aPListContains(aPlist* list, uint8_t iPort, uint8_t iAddr){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		if(iPort == list->values[i].destPort && iAddr == list->values[i].addr) return TRUE;
	}
	return FALSE;
}

#endif /* ACCEPTBUFFER_H */
