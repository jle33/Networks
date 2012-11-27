/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   Apr 28 2012
 * 
 */ 
#include <Timer.h>
#include "command.h"
#include "packet.h"
#include "dataStructures/list.h"
#include "dataStructures/pair.h"
#include "packBuffer.h"
#include "dataStructures/hashmap.h"

//Ping Includes
#include "dataStructures/pingList.h"
#include "ping.h"

//James added
#include "dataStructures/hashmap.h"
#include <string.h>
#include "dataStructures/LinkState.h"
#include "dataStructures/hashmapLSP.h"
#include "dataStructures/Dijkstra.h"
#include "TCPSocketAL.h"
#include "transport.h"
#include "stdio.h"
#include "stdlib.h"
#include "dataStructures/addrPort.h"

module Node{
	provides interface node<TCPSocketAL, transport>;
	uses interface Boot;
	uses interface Timer<TMilli> as pingTimeoutTimer;
	
	uses interface Random as Random;
	
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	//James Added
	uses interface Timer<TMilli> as LinkstateTimer;
	uses interface Timer<TMilli> as NeighborDiscoveryTimer;
	uses interface Timer<TMilli> as sendDelay;
	uses interface TCPManager<TCPSocketAL, addrPort> as TCPManager;
	uses interface TCPSocket<TCPSocketAL> as ALSocket;
	uses interface server<TCPSocketAL> as ALServer;
	uses interface client<TCPSocketAL> as ALClient;
}

implementation{
	uint16_t sequenceNum = 0;

	bool busy = FALSE;
	
	message_t pkt;
	pack sendPackage;
	
	sendBuffer packBuffer;	
	arrlist Received;
	
	//James Added
	hashmap ListofNeighbors;
	pair SRCSEQID;
	uint8_t NEIGHBORDISCOVERY[15] = {"NeighborPacket"}; //Adrian showed me how to initialize and create this message
	iterator NeighborIterator;
	uint16_t MyNeighborNodes;
	//LSPTable[0] will specify node 1 wtih some cost, good way to store it into the limited 20byte sized payload.
	LinkStateInfo LSPTable[LINKSTATESIZE];
	hashmapLSP ListOfLSP; 
	RoutingTable Confirmed;
	RoutingTable Tentative;
	//Project3
	uint16_t tcpDestAddr;
	uint8_t connectionAddr[5];
	uint8_t connectCount;
	bool isActive = TRUE;
	char *clser;

	
	//Ping/PingReply Variables
	pingList pings;
	uint8_t errorMsg;
	error_t send(uint16_t src, uint16_t dest, pack *message);
	void storeLSPintoList(LinkStateInfo *payload, pair srcAndseq);
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	task void sendBufferTask();
	
	event void Boot.booted(){
		call AMControl.start();
		hashmapInitLSP(&ListOfLSP);
		connectCount = 0;
		//dbg("genDebug", "Booted\n");
	}
	
	event void AMControl.startDone(error_t err){
		if(err == SUCCESS){
			call pingTimeoutTimer.startPeriodic(PING_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
			//James Added
			call NeighborDiscoveryTimer.startPeriodic(43673 + (uint16_t) ((call Random.rand16())%200));
			call LinkstateTimer.startPeriodic(81961 + (uint16_t) ((call Random.rand16())%200));
			call sendDelay.startOneShot( call Random.rand16() % 200);
			//call LinkstateTimer.startPeriodic(1375961 + (uint16_t) ((call Random.rand16())%200));
		}else{
			//Retry until successful
			call AMControl.start();
		}
	}
 	void delaySendTask(){
            call sendDelay.startOneShot( call Random.rand16() % 200);
        }
	event void AMControl.stopDone(error_t err){}
	event void sendDelay.fired(){
		  post sendBufferTask();
	}
	event void pingTimeoutTimer.fired(){
		checkTimes(&pings, call pingTimeoutTimer.getNow());
	}
	
	
	event void AMSend.sendDone(message_t* msg, error_t error){
		//Clear Flag, we can send again.
		if(&pkt == msg){
			//dbg("genDebug", "Packet Sent\n");
			busy = FALSE;
			//post sendBufferTask();
			delaySendTask();
		}
	}
	
	//James Added
	event void NeighborDiscoveryTimer.fired(){
		dbg("Project1N", "Sending Neighbor discovery packet\n");
		/*Adrian's Idea' Will clear the list of neighbor nodes before
		 the packet discovery is sent out which should take care of the nodes are inactive*/
		hashmapInit(&ListofNeighbors);
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_PING, sequenceNum++, NEIGHBORDISCOVERY, sizeof(NEIGHBORDISCOVERY));
		sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);	
		//post sendBufferTask();
		delaySendTask();
		}
	
	event void LinkstateTimer.fired(){ 
		uint8_t i = 0;
	
		for(i = 0; i < LINKSTATESIZE; i++){
			LSPTable[i].Cost = Infinite;
			if((TOS_NODE_ID) == i+1){
				LSPTable[i].Cost = 0;	
			}
		}
		iteratorInit(&NeighborIterator, &ListofNeighbors);
		while(iteratorHasNext(&NeighborIterator)){
			LSPTable[iteratorNext(&NeighborIterator)-1].Cost = 1;	
		}
		//Ya I can send to AM_BROADCAST_ADDR to send to neighbors, but this feels cleaner
		iteratorInit(&NeighborIterator, &ListofNeighbors);
		while(iteratorHasNext(&NeighborIterator)){
			MyNeighborNodes = iteratorNext(&NeighborIterator);
			//dbg("Project2", "Sending to Node %d\n", MyNeighborNodes);
			}
			makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKSTATE, sequenceNum++, &LSPTable, sizeof(LSPTable));
			sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);
			SRCSEQID.src = TOS_NODE_ID;
			SRCSEQID.seq = sequenceNum;
			storeLSPintoList(LSPTable, SRCSEQID);
	}
	
	/*void printLinkState(LinkStateInfo *payload, uint8_t srcNode){
		uint8_t i = 0;
		for(i = 0; i < LINKSTATESIZE; i++){
			dbg("Project2", "Node: %d, srcNode: %d, Cost: %d\n", i+1, srcNode, payload[i].Cost);
		}
	}*/
	void storeLSPintoList(LinkStateInfo *payload, pair srcAndseq){
	 	LPList LSP;
	 	uint8_t i = 0;
	 	LSP.myPair.src = srcAndseq.src;
	 	LSP.myPair.seq = srcAndseq.seq;
	 	
	 	for(i = 0; i < LINKSTATESIZE; i++){
	 		LSP.Neighbors[i].Neighbor = i+1;
	 		LSP.Neighbors[i].Cost = payload[i].Cost;
	 		}
	 	hashmapInsertLSP(&ListOfLSP, srcAndseq.src, LSP);
	 	}

	void StartDijkstraCalc(){
		uint8_t i = 0;
		dbg("Project2", "********Starting LinkState Calculations*******\n");
		InitializeTentativeTable(&Tentative);
		InitializeConfirmedTable(&Confirmed);
		do{
			//dbg("Project2", "Next: %d Confirmed Value: %d", Confirmed.RTable[Confirmed.numVals].Dest, Confirmed.numVals);
			LookAtLSP(&Tentative, &Confirmed, &ListOfLSP, Confirmed.RTable[Confirmed.numVals].Dest);
			if(Tentative.emptyCount == 20){
				break;
			}
			StoreOntoConfirmed(&Tentative, &Confirmed);
			//dbg("Project2D", "emptyCount: %d\n", Tentative.emptyCount);
		}
		while(TRUE);
			
		dbg("Project2", "\tThe Confirmed List\n");
		dbg("Project2", "Dest\t\tCost\t\tNxtHop\t\n");
		for(i=0; i < Confirmed.numVals + 1; i++){
			dbg("Project2","%d\t\t%d\t\t%d\t\n", Confirmed.RTable[i].Dest, Confirmed.RTable[i].Cost, Confirmed.RTable[i].NxtHop);
		}
	}
	
	void printLSPList(uint8_t src){
		uint8_t i = 0, j=0;
		LPList LSP;
		dbg("Project2","Current Node:\t%d\n*\n*\n", TOS_NODE_ID);
		for(i=0; i < ListOfLSP.numofVals; i++){
			LSP = hashmapGetLSP(&ListOfLSP, ListOfLSP.keys[i]);
			dbg("Project2","The Source Node is:\t%d\n*\n*\n", ListOfLSP.keys[i]);
			dbg("Project2","SRCNode\tSEQ\tNeighbor\tCost\n");
			for(j=0; j < LINKSTATESIZE; j++){
				dbg("Project2", "%d\t\t%d\t%d\t\t%d\n", LSP.myPair.src, LSP.myPair.seq, LSP.Neighbors[j].Neighbor, LSP.Neighbors[j].Cost);	
			}
		}
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		//dbg("Project1F", "Recieve\n");	
		uint8_t Entry = 0;
		if(!isActive){
			dbg("genDebug", "The Node is inactive, packet will not be read.");
			return msg;	
		}
		if(len==sizeof(pack)){
			pack* myMsg=(pack*) payload;
			//TOS_NODE_ID - is the current node. 
			//James Added, each time a packet is send, increment the seq
			
			dbg("mydebug", "Current Dest: %d SRCSEQID - src:%d  seq:%d \n", myMsg->dest, myMsg->src, myMsg->seq);
			SRCSEQID.src =  myMsg->src;
			SRCSEQID.seq =  myMsg->seq;
			if(myMsg->protocol == PROTOCOL_LINKSTATE){
					//payload should hold the cost, and the directly connected Neighbors.
					dbg("Project2", "Receieved linkstate packet from node %d\n*\n*\n*\n", myMsg->src);
					if(hashmapContainsLSP(&ListOfLSP, SRCSEQID.src) == TRUE){
						LPList seqCheck = hashmapGetLSP(&ListOfLSP, SRCSEQID.src);
						dbg("Project2", "LSP with SRC in list, checking SEQ\n*\n*\n*\n", SRCSEQID.src);
						if(SRCSEQID.seq > seqCheck.myPair.seq){
							dbg("Project2", "SeqNumber: %d is newer, updating list\n*\n*\n*\n", SRCSEQID.seq);
							storeLSPintoList(myMsg->payload,SRCSEQID);
						}
						else{
							dbg("Project2", "SeqNumber the same dropping LSP\n*\n*\n");
							return msg;
							}
					}else{
						dbg("Project2","Storing Link State Packet into List\n\n");
						storeLSPintoList(myMsg->payload,SRCSEQID);
					}
					printLSPList(myMsg->src);	
					//printLinkState(myMsg->payload, myMsg->src);
					/*iteratorResetPos(&NeighborIterator);
					while(iteratorHasNext(&NeighborIterator)){
						MyNeighborNodes = iteratorNext(&NeighborIterator);
					//	if(MyNeighborNodes == myMsg->src){
							dbg("Project2", "Forwarding Packets to Node %d\n", MyNeighborNodes);
						//}
					}*/
					makePack(&sendPackage, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL, myMsg->protocol, myMsg->seq, myMsg->payload, sizeof(myMsg->payload));
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);
					//	}
					//}
				return msg;
			}
			

		    if(arrListContains(&Received, SRCSEQID.src, SRCSEQID.seq) == FALSE){
				bool ListNotOverflow = arrListPushBack(&Received, SRCSEQID);
				//dbg("Project1F", "Storing packet onto Receieved list\n");
				if(ListNotOverflow == FALSE){
					//dbg("Project1F", "Received list is full unable to put onto it, Removing previous packets\n");
					//Assume that the last packet within the list has timed-out
					pop_front(&Received);
					ListNotOverflow = arrListPushBack(&Received, SRCSEQID);
					if(ListNotOverflow== FALSE){
						dbg("Project1F", "Something Bad\n");
					}
					else{
						dbg("Project1F", "Passed\n");
					}
					//If full just drop
					//return msg;
				}
				//dbg("mydebug", "Packet will be put onto the Receieved List with ID src: %d  seq: %d\n", myMsg->src, myMsg->seq);
			}
			else{
				//dbg("Project1F", "Current packet has reached this node already. SRCSEQID SRC: %d, SEQ: %d\n", SRCSEQID.src,SRCSEQID.seq);
				//dbg("mydebug", "Current packet has reached this node already.\n");
				dbg("Project1F","Packet Dropped\n");
				return msg;
			}
			if(TOS_NODE_ID==myMsg->dest){				
				//dbg("genDebug", "Packet from %d has arrived! Msg: %s\n", myMsg->src, myMsg->payload);
				switch(myMsg->protocol){
					uint8_t srcPort;
					uint8_t destPort;
					uint8_t createMsg[PACKET_MAX_PAYLOAD_SIZE];
					uint16_t dest;
					case PROTOCOL_PING:
						dbg("genDebug", "Sending Ping Reply to %d! \n", myMsg->src);
						StartDijkstraCalc();
						for(Entry=0; Entry < Confirmed.numVals; Entry++){
							if(myMsg->src == Confirmed.RTable[Entry].Dest){
								dbg("Project2", "myMsg->dest: %d is at DEST: %d  at Entry: %d\n", myMsg->src, Confirmed.RTable[Entry].Dest, Entry);
								break;
							}
							dbg("Project2", "Entry: %d, Confirmed Table: %d \n", Entry, Confirmed.RTable[Entry].Dest);
						}
						dbg("Project2", "Taking Route (Dest: %d, Cost: %d, NxtHop: %d)\n", Confirmed.RTable[Entry].Dest, Confirmed.RTable[Entry].Cost, Confirmed.RTable[Entry].NxtHop);
						makePack(&sendPackage, TOS_NODE_ID, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
						//The Send Buffer should send to the am broadcast addr
						sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, Confirmed.RTable[Entry].NxtHop);	
						//post sendBufferTask();
						delaySendTask();
						break;
					case PROTOCOL_PINGREPLY:
						//dbg("genDebug", "Received a Ping Reply from %d!\n", myMsg->src);
						if((strcmp(myMsg->payload,NEIGHBORDISCOVERY) == 0) && (myMsg->TTL == 0)){//Apparently False is true for strcmp							
							uint8_t key = hash(myMsg->src);
							if(hashmapContains(&ListofNeighbors, (uint8_t) key)==FALSE){
								dbg("mydebug", "Hashmap does not contain the key: %d and node: %d\n", key, myMsg->src);
								hashmapInsert(&ListofNeighbors, (uint8_t) key, myMsg->src);					
							}
							else{
								dbg("mydebug", "Hashmap contains the key: %d and node: %d\n", key, myMsg->src);
								//hashmapRemove(&ListofNeighbors, (uint8_t) key);
							}
							//dbg("mydebug","#######Storing#######\n");
							dbg("Project1N","\n");
							dbg("Project1N","#### Node %d Neighbors ####\n",TOS_NODE_ID);
							iteratorInit(&NeighborIterator, &ListofNeighbors);
							while(iteratorHasNext(&NeighborIterator)){
								dbg("Project1N", "Neighbor:  %d\n" , iteratorNext(&NeighborIterator));
							}
							dbg("Project1N","Done\n");
							dbg("Project1N","###########################\n");						
						}
						break;
					case PROTOCOL_CMD:
							switch(getCMD((uint8_t *) & myMsg->payload, sizeof(myMsg->payload))){
								uint32_t temp=0;
								TCPSocketAL *mSocket;
								case CMD_PING:
								   // dbg("genDebug", "Ping packet received: %lu\n", temp);
									memcpy(&createMsg, (myMsg->payload) + PING_CMD_LENGTH, sizeof(myMsg->payload) - PING_CMD_LENGTH);
									memcpy(&dest, (myMsg->payload)+ PING_CMD_LENGTH-2, sizeof(uint8_t));
									makePack(&sendPackage, TOS_NODE_ID, (dest-48)&(0x00FF), MAX_TTL, PROTOCOL_PING, sequenceNum++, (uint8_t *)createMsg,
									sizeof(createMsg));	
									//Place in Send Buffer
									sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
									//post sendBufferTask();
									delaySendTask();
									break;
								case CMD_KILL:
									isActive = FALSE;
									break;
								case CMD_ERROR:
									break;
								case CMD_TEST_CLIENT:
										clser = myMsg->payload;
										clser = strtok(clser," ");
										clser = strtok(NULL, " ");
										clser = strtok(NULL, " ");
										srcPort = atoi(clser);
										clser = strtok(NULL, " ");
										destPort = atoi(clser);
										clser = strtok(NULL, " ");
										dest = atoi(clser);
										
										call TCPManager.init();
										mSocket = call TCPManager.socket();
										errorMsg = call ALSocket.bind(mSocket, srcPort, TOS_NODE_ID);
										if(errorMsg == -1){
											dbg("project3", "Problem with binding\n");
											break;
										}
										call ALSocket.connect(mSocket, dest, destPort);
										dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", mSocket->ID, mSocket->destPort, mSocket->destAddr, mSocket->SrcPort, mSocket->SrcAddr, mSocket->state );
										
										call ALClient.init(mSocket);
									break;
								case CMD_TEST_SERVER:
										clser = myMsg->payload;
										clser = strtok(clser," ");
										clser = strtok(NULL, " ");
										clser = strtok(NULL, " ");
										srcPort = atoi(clser);
										call TCPManager.init();
										mSocket = call TCPManager.socket();
										call ALSocket.bind(mSocket, srcPort, TOS_NODE_ID);
										//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", mSocket->ID, mSocket->destPort, mSocket->destAddr, mSocket->SrcPort, mSocket->SrcAddr, mSocket->state );

										call ALSocket.listen(mSocket, 5);
										dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", mSocket->ID, mSocket->destPort, mSocket->destAddr, mSocket->SrcPort, mSocket->SrcAddr, mSocket->state );	
										call ALServer.init(mSocket);
									break;
								default:
									break;
							}
						break;
						case PROTOCOL_TCP: 
							//dbg("project3","Handling Packet\n" );
							//Store dest addr somehow for server
							call TCPManager.handlePacket(&myMsg->payload, myMsg->src);
						break;
					default:
						break;
				}
				return msg;
			}if(TOS_NODE_ID==myMsg->src){
				dbg("cmdDebug", "Source is this node: %s\n", myMsg->payload);
				return msg;
			}
			if(TOS_NODE_ID != myMsg->dest){
				//dbg("mydebug", "Neighbor: %s Payload Msg %s\n", NEIGHBORDISCOVERY, myMsg->payload);
				dbg("mydebug", "myMsg->dest = %d", myMsg->dest);
				if((strcmp(myMsg->payload,NEIGHBORDISCOVERY) == 0) && (myMsg->protocol == PROTOCOL_PING) && (myMsg->dest == AM_BROADCAST_ADDR)){
					dbg("mydebug","Recieved Neighbor Discovery packet from %d\n", myMsg->src);
					dbg("Project1N", "Received Neighbor packet\n");
					makePack(&sendPackage, TOS_NODE_ID, myMsg->src, 1, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
					dbg("mydebug","Sending from src: %d to dest: %d\n", sendPackage.src, sendPackage.dest);
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
					//post sendBufferTask();
					delaySendTask();
				}
				else{
				//	dbg("Project1F", "Rebroadcasting to AM_BROADCAST_ADDR\n");
					StartDijkstraCalc();
					for(Entry=0; Entry < Confirmed.numVals; Entry++){
						if(myMsg->dest == Confirmed.RTable[Entry].Dest){
							dbg("Project2D", "myMsg->dest: %d is at DEST: %d  at Entry: %d\n", myMsg->dest, Confirmed.RTable[Entry].Dest, Entry);
							break;
						}
					}
					dbg("Project3", "Protocol %d Taking Route (Dest: %d, Cost: %d, NxtHop: %d)\n",myMsg->protocol, Confirmed.RTable[Entry].Dest, Confirmed.RTable[Entry].Cost, Confirmed.RTable[Entry].NxtHop);
					makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, Confirmed.RTable[Entry].NxtHop);
					//post sendBufferTask();
					delaySendTask();
				}
			}
			return msg;
		}
		dbg("genDebug", "Unknown Packet Type\n");
		return msg;
	}
	void storeAddr(uint8_t dest){
		connectionAddr[connectCount] = dest;
	}
	
	//For connect
	command void node.TCPPacket(transport *transportPacket, TCPSocketAL *Sckt){
		uint8_t Entry = 0;
		uint8_t storecount = 0;
		//transport* sup = (transport*)transportPacket;
		StartDijkstraCalc();	
		for(Entry=0; Entry < Confirmed.numVals; Entry++){
			if(Sckt->destAddr == Confirmed.RTable[Entry].Dest){
				break;
			}
		}
		//printTransport(transportPacket);
		//dbg("project3", "seq %d\n", sequenceNum);
		makePack(&sendPackage, TOS_NODE_ID, Sckt->destAddr, MAX_TTL, PROTOCOL_TCP, sequenceNum++, transportPacket, sizeof(transportPacket));
		
		//	for(storecount = 0; storecount < sizeof(sup->payload); storecount++){
		//		dbg("project3", "%d Sending TCPPacket %d\n", sizeof(sup->payload) ,	sup->payload[storecount]);
		//	}
		//dbg("project3", "Sending from %d to %d\n", sendPackage.src, sendPackage.dest);
		sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, Confirmed.RTable[Entry].NxtHop);
		delaySendTask();
	}

	task void sendBufferTask(){
		if(packBuffer.size !=0 && !busy){
			sendInfo info;
			info = sendBufferPopFront(&packBuffer);
			send(info.src,info.dest, &(info.packet));
		}
		
		if(packBuffer.size !=0 && !busy){
			//post sendBufferTask();
			delaySendTask();
		}
	}

	/*
	* Send a packet
	*
	*@param
	*	src - source address
	*	dest - destination address
	*	msg - payload to be sent
	*
	*@return
	*	error_t - Returns SUCCESS, EBUSY when the system is too busy using the radio, or FAIL.
	*/
	error_t send(uint16_t src, uint16_t dest, pack *message){
		if(!busy && isActive){
			
			pack* msg = (pack *)(call Packet.getPayload(&pkt, sizeof(pack) ));			
			*msg = *message;
			//TTL Check
			if(msg->TTL >0)msg->TTL--;
			else return FAIL;
	
			if(call AMSend.send(dest, &pkt, sizeof(pack)) ==SUCCESS){
				busy = TRUE;
				return SUCCESS;
			}else{
				dbg("genDebug","The radio is busy, or something\n");
				return FAIL;
			}
		}else{
			return EBUSY;
		}
		dbg("genDebug", "FAILED!?");
		return FAIL;
	}	

	
	
//Re wrapping, after un-wrapping
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		//dbg("mydebug" ,"calling makePack creating Packet, SRC: %d, DEST: %d, TTL: %d, SEQ: %d \n", src, dest, TTL, seq);
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
	}



}
