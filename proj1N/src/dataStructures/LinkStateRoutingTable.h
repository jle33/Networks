#ifndef LINKSTATEROUTINGTABLE_H
#define LINKSTATEROUTINGTABLE_H
#include "../packet.h"
#include "dataStructures/hashmap.h"

enum{
	LINKSTATESIZE = 20,
	Infinite = 255	
};

typedef struct LinkStateInfo{
	uint8_t Cost;
}LinkStateInfo;

typedef struct RoutingTableInfo{
	uint8_t NxtHop;
	uint8_t Cost;
	uint8_t Dest;
}RoutingTableInfo;

typedef struct RoutingTable{
	RoutingTableInfo RTable[LINKSTATESIZE];
	uint8_t numVals;
}RoutingTable;

void routeTableUpdate(RoutingTable* input, uint8_t cost, uint8_t dest){
	uint8_t i = 0;
	
}

#endif /* LINKSTATEROUTINGTABLE_H */