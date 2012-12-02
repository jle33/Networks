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



module Node{
	uses interface Boot;
	uses interface Timer<TMilli> as pingTimeoutTimer;
	
	uses interface Random as Random;
	
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	//James Added
	uses interface Timer<TMilli> as NeighborDiscoveryTimer;
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

	bool isActive = TRUE;

	//Ping/PingReply Variables
	pingList pings;

	error_t send(uint16_t src, uint16_t dest, pack *message);
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	task void sendBufferTask();
			
	event void Boot.booted(){
		call AMControl.start();
		dbg("genDebug", "Booted\n");
	}

	event void AMControl.startDone(error_t err){
		if(err == SUCCESS){
			call pingTimeoutTimer.startPeriodic(PING_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
			//James Added
			call NeighborDiscoveryTimer.startPeriodic(50000 + (uint16_t) ((call Random.rand16())%200));
		}else{
			//Retry until successful
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err){}
	
	event void pingTimeoutTimer.fired(){
		checkTimes(&pings, call pingTimeoutTimer.getNow());
	}
	
	
	event void AMSend.sendDone(message_t* msg, error_t error){
		//Clear Flag, we can send again.
		if(&pkt == msg){
			dbg("genDebug", "Packet Sent\n");
			busy = FALSE;
			post sendBufferTask();
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
		//makePack(&sendPackage, TOS_NODE_ID, 4, 1, PROTOCOL_PING, sequenceNum++, NEIGHBORDISCOVERY, sizeof(NEIGHBORDISCOVERY));
		//sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, 4);	
		post sendBufferTask();
		}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		//dbg("Project1F", "Recieve\n");	
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
			if(arrListContains(&Received, SRCSEQID.src, SRCSEQID.seq) == FALSE){
				bool ListNotOverflow = arrListPushBack(&Received, SRCSEQID);
				dbg("Project1F", "Storing packet onto Receieved list\n");
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
				dbg("mydebug", "Packet will be put onto the Receieved List with ID src: %d  seq: %d\n", myMsg->src, myMsg->seq);
			}
			else{
				//dbg("Project1F", "Current packet has reached this node already. SRCSEQID SRC: %d, SEQ: %d\n", SRCSEQID.src,SRCSEQID.seq);
				//dbg("mydebug", "Current packet has reached this node already.\n");
				dbg("Project1F","Packet Dropped\n");
				return msg;
			}
			
			if(TOS_NODE_ID==myMsg->dest){				
				dbg("genDebug", "Packet from %d has arrived! Msg: %s\n", myMsg->src, myMsg->payload);
				switch(myMsg->protocol){
					uint8_t createMsg[PACKET_MAX_PAYLOAD_SIZE];
					uint16_t dest;
					case PROTOCOL_PING:
						dbg("genDebug", "Sending Ping Reply to %d! \n", myMsg->src);
						makePack(&sendPackage, TOS_NODE_ID, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
						//The Send Buffer should send to the am broadcast addr
						sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);	
						post sendBufferTask();
						break;
					case PROTOCOL_PINGREPLY:
						dbg("genDebug", "Received a Ping Reply from %d!\n", myMsg->src);
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
							switch(getCMD((uint8_t *) &myMsg->payload, sizeof(myMsg->payload))){
								uint32_t temp=0;
								case CMD_PING:
								    dbg("genDebug", "Ping packet received: %lu\n", temp);
									memcpy(&createMsg, (myMsg->payload) + PING_CMD_LENGTH, sizeof(myMsg->payload) - PING_CMD_LENGTH);
									memcpy(&dest, (myMsg->payload)+ PING_CMD_LENGTH-2, sizeof(uint8_t));
									makePack(&sendPackage, TOS_NODE_ID, (dest-48)&(0x00FF), MAX_TTL, PROTOCOL_PING, sequenceNum++, (uint8_t *)createMsg,
									sizeof(createMsg));	
									//Place in Send Buffer
									sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
									post sendBufferTask();
									break;
								case CMD_KILL:
									isActive = FALSE;
									break;
								case CMD_ERROR:
									break;
								default:
									break;
							}
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
					post sendBufferTask();
				}
				else{
					dbg("Project1F", "Rebroadcasting to AM_BROADCAST_ADDR\n");
					makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);
					post sendBufferTask();
				}
			}
			return msg;
		}
		dbg("genDebug", "Unknown Packet Type\n");
		return msg;
	}

	task void sendBufferTask(){
		if(packBuffer.size !=0 && !busy){
			sendInfo info;
			info = sendBufferPopFront(&packBuffer);
			send(info.src,info.dest, &(info.packet));
		}
		
		if(packBuffer.size !=0 && !busy){
			post sendBufferTask();
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
