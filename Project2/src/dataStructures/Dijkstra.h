#ifndef DIJKSTRA_H
#define DIJKSTRA_H
#include "dataStructures/LinkState.h"
#include "dataStructures/hashmapLSP.h"

/*The Routing Table Info*/
typedef struct RoutingTableInfo{
	uint8_t NxtHop;
	uint8_t Cost;
	uint8_t Dest;
}RoutingTableInfo;


typedef struct RoutingTable{
	RoutingTableInfo RTable[LINKSTATESIZE];
	uint8_t numVals;
	uint8_t emptyCount;
}RoutingTable;

void InitializeTentativeTable(RoutingTable *Tentative){
	Tentative->numVals=0;
	Tentative->emptyCount = LINKSTATESIZE;
	while(Tentative->numVals < LINKSTATESIZE){
		//dbg("Project2D","MEOW");
		Tentative->RTable[Tentative->numVals].Dest = 0;
		Tentative->RTable[Tentative->numVals].Cost = 255;
		Tentative->RTable[Tentative->numVals].NxtHop = 0;
		Tentative->numVals++;
		}
	Tentative->numVals = 0;		
}

void InitializeConfirmedTable(RoutingTable *confirmed){
	
	confirmed->RTable[confirmed->numVals].Dest = TOS_NODE_ID;
	confirmed->RTable[confirmed->numVals].Cost = 0;
	confirmed->RTable[confirmed->numVals].NxtHop = TOS_NODE_ID;
	confirmed->numVals=1;
		while(confirmed->numVals < LINKSTATESIZE){
		//dbg("Project2D","MEOW");
		confirmed->RTable[confirmed->numVals].Dest = 0;
		confirmed->RTable[confirmed->numVals].Cost = 255;
		confirmed->RTable[confirmed->numVals].NxtHop = 0;
		confirmed->numVals++;
		}
	confirmed->numVals = 0;	
}

bool RouteTableisEmpty(RoutingTable *input){
	dbg("Project2D", "emptyCount: %d\n", input->emptyCount);
	if(input->emptyCount == LINKSTATESIZE){
			dbg("Project2D", "emptyCount: %d LINKSTATESIZE %d\n", input->emptyCount, LINKSTATESIZE);
		return TRUE;
	}
	else
	return FALSE;
}
/*Should look at the neighbors*/
void LookAtLSP(RoutingTable *Tentative, RoutingTable *Confirmed,  hashmapLSP *ListOfLSP, uint8_t next){
	LPList LSP;
	uint8_t i = 0;
	bool inConfirmed = FALSE;
	bool inTentative = FALSE;
	uint8_t currentIndex = 0;
	uint8_t TempCost, TempDest, TempNxt;
	LSP = hashmapGetLSP(ListOfLSP, next);
	
	dbg("Project2D", "Checking LSP of %d %d\n", LSP.myPair.src, next);
			
			dbg("Project2D", "START!!!!!!!!!!!!!!!!numVals %d\n", Tentative->numVals);
			
			for(i=0; i < LINKSTATESIZE; i++){
				inTentative = FALSE;
				inConfirmed = FALSE;
				dbg("Project2D", "Looking up LSP List, entry %d\n", i);
				if((LSP.Neighbors[i].Cost != 255)){
						TempDest = LSP.Neighbors[i].Neighbor;
						TempCost = LSP.Neighbors[i].Cost + Confirmed->RTable[Confirmed->numVals].Cost;
						if(Confirmed->RTable[Confirmed->numVals].Dest != TOS_NODE_ID){
							TempNxt = Confirmed->RTable[Confirmed->numVals].NxtHop;
						}
						else{
							TempNxt = LSP.Neighbors[i].Neighbor;
						}
						//dbg("Project2D", "Tentative(%d, %d, %d)\n")
						currentIndex = 0;	
						dbg("Project2D", "Confirmed->numVals: %d\n", (Confirmed->numVals));
						while(currentIndex < (Confirmed->numVals+1)){
							
							if(TempDest == Confirmed->RTable[currentIndex].Dest){
								dbg("Project2D", "in Confirmed Don't do anything\n");
								inConfirmed = TRUE;
								}
							currentIndex++;
							}
						currentIndex = 0;
						while(currentIndex < (Tentative->numVals+ 1)){
							if(TempDest == Tentative->RTable[currentIndex].Dest){
								dbg("Project2D", "in Tentative Don't do anything\n");
								inTentative = TRUE;
								break; //There should only be one Unique Dest/Node
								}
								currentIndex++;
							}
						if((inConfirmed == FALSE) && (inTentative == FALSE)){
							dbg("Project2D","Adding to Tentative Table with (%d, %d, %d)\n", TempDest, TempCost, TempNxt);
							Tentative->RTable[Tentative->numVals].Dest = TempDest;
							Tentative->RTable[Tentative->numVals].Cost = TempCost;
							Tentative->RTable[Tentative->numVals].NxtHop = TempNxt;
							Tentative->numVals++;
							Tentative->emptyCount--;
						}
						if((inConfirmed == FALSE) && (inTentative == TRUE) && (TempCost < Tentative->RTable[currentIndex].Cost)){
							dbg("Project2D","Updating Tentative Table from (%d, %d, %d) with (%d, %d, %d)\n",Tentative->RTable[currentIndex].Dest, Tentative->RTable[currentIndex].Cost, Tentative->RTable[currentIndex].NxtHop, TempDest, TempCost, TempNxt);
							Tentative->RTable[currentIndex].Dest = TempDest;
							Tentative->RTable[currentIndex].Cost = TempCost;
							Tentative->RTable[currentIndex].NxtHop = TempNxt;
						}
				}
			}

}

/*Find the LSP with the lowest cost within the Tentative list and store onto Confirmed list*/
void StoreOntoConfirmed(RoutingTable *Tentative, RoutingTable *Confirmed){
	uint8_t i = 0;
	uint8_t MINCOST = 255;
	uint8_t Currententry;
	
	dbg("Project2D", "Storing onto Confirmed\n");
	//Stores the entry with the lowest cost;
	for(i=0; i < Tentative->numVals; i++){
		dbg("Project2D", "Neighbor %d Cost %d  < MINCOST %d \n", Tentative->RTable[i].Dest, Tentative->RTable[i].Cost, MINCOST );
		if(Tentative->RTable[i].Cost < MINCOST){
				MINCOST = Tentative->RTable[i].Cost;
				Currententry = i;
			}
		}
	dbg("Project2D", "Tentative (%d, %d, %d)\n", Tentative->RTable[Currententry].Dest, Tentative->RTable[Currententry].Cost,Tentative->RTable[Currententry].NxtHop );	
	dbg("Project2D", "Confirmed (%d, %d, %d)\n", Confirmed->RTable[Confirmed->numVals].Dest, Confirmed->RTable[Confirmed->numVals].Cost, Confirmed->RTable[Confirmed->numVals].NxtHop);	
	
	Confirmed->numVals++;
	Confirmed->RTable[Confirmed->numVals].Dest = Tentative->RTable[Currententry].Dest;
	Confirmed->RTable[Confirmed->numVals].Cost = Tentative->RTable[Currententry].Cost;
	Confirmed->RTable[Confirmed->numVals].NxtHop = Tentative->RTable[Currententry].NxtHop;
	dbg("Project2D", "Confirmed (%d, %d, %d)\n", Confirmed->RTable[Confirmed->numVals].Dest, Confirmed->RTable[Confirmed->numVals].Cost, Confirmed->RTable[Confirmed->numVals].NxtHop);	
	Tentative->RTable[Currententry].Dest = 0;
	Tentative->RTable[Currententry].Cost = 255;
	Tentative->RTable[Currententry].NxtHop = 255;
	Tentative->emptyCount++;
	dbg("Project2D", "emptyCount: %d\n", Tentative->emptyCount);
	/*if(Tentative->emptyCount == LINKSTATESIZE){
		InitializeTentativeTable(Tentative);
		}	*/
}


	



#endif