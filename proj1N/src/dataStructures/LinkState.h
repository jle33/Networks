#ifndef LINKSTATE_H
#define LINKSTATE_H
#include "../packet.h"
#include "dataStructures/pair.h"
//typedef pair PACKETID;
/*The Link State Packet Info*/

enum{
	//Based on limit of the payload, can only send 20 bytes worth of data
	LINKSTATESIZE = 20,
	Infinite = 255,
	MAXNODES = 20	
};

/*Mainly for sending the payload*/
typedef struct LinkStateInfo{
	uint8_t Cost;
}LinkStateInfo;

/*This just makes it easier to hold the Neighbors and Cost*/
typedef struct myNeighbor{
	uint8_t Cost;
	uint16_t Neighbor;
}myNeighbor;

/*Will Store the LSP packets, should hold the Source Node and its info*/
typedef struct LPList{
	pair myPair;//contains src and seq
	myNeighbor Neighbors[MAXNODES];
}LPList;


#endif /* LINKSTATE_H */