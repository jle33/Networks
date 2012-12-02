//Author: UCM ANDES Lab
#ifndef FREESOCKETLIST_H
#define FREESOCKETLIST_H

typedef uint8_t TypeofData;
#define INDEXSIZE 255
#define MAXNUMSIZEVALS INDEXSIZE

typedef struct scktlist
{	
	TypeofData values[INDEXSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}scktlist;

void scktListInit(scktlist *cur){
	cur->numValues = 0;	
}

bool scktListPushBack(scktlist* cur, TypeofData newVal){
	if(cur->numValues != MAXNUMSIZEVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool scktListPushFront(scktlist* cur, TypeofData newVal){
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

TypeofData scktpop_back(scktlist* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

TypeofData scktpop_front(scktlist* cur){
	TypeofData returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

TypeofData scktfront(scktlist* cur)
{
	return cur->values[0];
}

TypeofData scktback(scktlist * cur)
{
	return cur->values[cur->numValues-1];	
}

bool scktListIsEmpty(scktlist* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t scktListSize(scktlist* cur){	return cur->numValues;}

void scktListClear(scktlist* cur){	cur->numValues = 0;}

TypeofData scktListGet(scktlist* cur, nx_uint8_t i){	return cur->values[i];}
/*
bool scktListContains(scktlist* list, uint8_t iSrc, uint8_t iSeq){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		if(iSeq == list->values[i].seq && iSrc == list->values[i].src) return TRUE;
	}
	return FALSE;
}*/

#endif /* FREESOCKETLIST_H */
