																							#include "TCPSocketAL.h"
#include "../packet.h"
#include "transport.h"
#include "Buffer.h"	
#include "ports.h"
#include "dataStructures/FreeSocketlist.h"
#include "dataStructures/AcceptBuffer.h"
#include "dataStructures/ClosingSockets.h"

module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, addrPort>;
	uses interface TCPSocket<TCPSocketAL>;	
	uses interface node<TCPSocketAL>;
	uses interface Timer<TMilli> as CloseTimer;
	uses interface Timer<TMilli> as ShutDownTimer;
	uses interface Random;
}
implementation{
	TCPSocketAL avilableSockets[TRANSPORT_MAX_PORT];
	port ports[TRANSPORT_MAX_PORT];
	transport sendTCP;
	uint16_t ExpectedseqNum;
	uint8_t scktID;
	scktlist freedSockets;
	aPlist acceptBuffer;
	addrPort Pairs;
	uint8_t ListenID;
	PendClose CloseMe[5];
	uint8_t closeCount = 0;
	
	void initSockets(){
		int i = 0;
		for (i = 0; i < TRANSPORT_MAX_PORT; i++){
			call TCPSocket.init(&avilableSockets[i]);
			
		}
	}
	void PendCloseInt(){
		int i = 0;
		for(i=0; i < 5; i++){
			CloseMe[i].PackArr = FALSE;
			CloseMe[i].scktID = -1;
		}
	}
	bool IDinClose(uint16_t ID){
		int i = 0;
		for(i=0; i < 5; i++){
			if(CloseMe[i].scktID == ID){
				return TRUE;
				}
		}
		return FALSE;
	}
	
	void initPorts(){
		int i = 0;
		for(i = 0; i < TRANSPORT_MAX_PORT; i++){
			ports[i].isUsed = FALSE;
			ports[i].scktID = 255;
		}
	}
	
	command void TCPManager.storeOntoActiveSocketsList(TCPSocketAL *input){
	/*avilableSockets[input->SrcPort].destPort = input->destPort;
		avilableSockets[input->SrcPort].destAddr = input->destAddr;
		avilableSockets[input->SrcPort].SrcPort = input->SrcPort;
		avilableSockets[input->SrcPort].SrcAddr = input->SrcAddr; //current socket at this host
		avilableSockets[input->SrcPort].state = input->state;
		avilableSockets[input->SrcPort].connections = input->connections;
		avilableSockets[input->SrcPort].RWS = input->RWS;
		avilableSockets[input->SrcPort].SWS = input->SWS;*/
		//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", avilableSockets[0].ID, avilableSockets[0].destPort, avilableSockets[0].destAddr, avilableSockets[0].SrcPort, avilableSockets[0].SrcAddr, avilableSockets[0].state );
	
	}
	
	
	command void TCPManager.init(){
		PendCloseInt();
		aPListInit(&acceptBuffer);
		scktListInit(&freedSockets);
		initSockets();
		initPorts();
		ExpectedseqNum = 0;
		scktID = 0;
	}
	
	command uint8_t TCPManager.portCheck(uint8_t localPort, uint16_t socketID){
		if((localPort > 255) || (ports[localPort].isUsed == TRUE)){
			return -1;
		}
		else if(localPort == 0){
			uint8_t i = 1;
			while(ports[i].isUsed == TRUE){
				i++;
				if(i > 255){
					dbg("project3", "No Ports Avaliable\n");
					return -1;
				}
			}
			ports[i].isUsed = TRUE;
			ports[i].scktID = socketID;
			return i;
		}
		ports[localPort].isUsed = TRUE;
		ports[localPort].scktID = socketID;
		return localPort;	
	}
	
	command TCPSocketAL *TCPManager.socket(){
		uint16_t temp = scktID;
		if(temp > 255){
			temp = scktpop_front(&freedSockets);
			avilableSockets[temp].ID = temp;
		}
		else{
			avilableSockets[scktID].ID = scktID;
			scktID++;
		}
		//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", avilableSockets[temp].ID, avilableSockets[temp].destPort, avilableSockets[temp].destAddr, avilableSockets[temp].SrcPort, avilableSockets[temp].SrcAddr, avilableSockets[temp].state );
		return &avilableSockets[temp];
	}
	
	command void TCPManager.handlePacket(void *payload, uint16_t destAddr){
		transport* myMsg = (transport*) payload;
		uint16_t sckID = ports[myMsg->destPort].scktID;
		switch(myMsg->type){
			case TRANSPORT_SYN:
			//	dbg("project3", "SYN packet\n destPort %d  ports.scktID %d ports.isUsed %d\n", myMsg->destPort, ports[myMsg->destPort].scktID, ports[myMsg->destPort].isUsed);
			//	dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
				if(avilableSockets[ports[myMsg->destPort].scktID].state == LISTEN){
					ListenID = sckID;
					Pairs.addr = destAddr;
					Pairs.destPort = myMsg->srcPort;
					aPListPushBack(&acceptBuffer, Pairs);
					avilableSockets[sckID].pendCon++;
					//dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
				}
				else{
					dbg("project3", "FIN PACKET SENDING\n");
				//	avilableSockets[ports[myMsg->destPort].scktID].destAddr = destAddr;
				//	createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				//	call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
				}
				
			break;
			case TRANSPORT_ACK:
				//dbg("project3", "ACK packet\n");
				if(avilableSockets[sckID].state == SYN_SENT ){
					avilableSockets[sckID].destPort = myMsg->srcPort;
					avilableSockets[sckID].state = ESTABLISHED;
					dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
				}
				else if(avilableSockets[sckID].state == ESTABLISHED){
					//Assume you sent data packets
					
				}
				else{
				}
				
			break;
			case TRANSPORT_FIN:
				dbg("project3", "FIN packet\n");
				//dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
				if(avilableSockets[sckID].state == CLOSING){
					call TCPManager.freeSocket(&avilableSockets[sckID]);
				}else if(avilableSockets[sckID].state == LISTEN){
					
				}else if(avilableSockets[sckID].state == ESTABLISHED){
					createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
					call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					//avilableSockets[sckID].state = SHUTDOWN;
					dbg("project3", "Socket ID %d\n", sckID);
					CloseMe[0].scktID = sckID;
					closeCount = 0;
					call ShutDownTimer.startPeriodic(60000 + (uint16_t) ((call Random.rand16())%200));
				}else{
					createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
					call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					call TCPManager.freeSocket(&avilableSockets[sckID]);
				}

			break;
			case TRANSPORT_DATA:
				//dbg("project3", "Data packet\n");
				if(avilableSockets[sckID].state == ESTABLISHED){
					uint16_t Seq = myMsg->seq;				
					if(ExpectedseqNum == Seq){
						createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_ACK, 0, ExpectedseqNum, NULL, 0);
						call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
						ExpectedseqNum = Seq;
					}
					else{
						createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_ACK, 0, Seq, NULL, 0);
						call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					}
					dbg("project3", "Data: %d\n", myMsg->payload[0]);
					call TCPSocket.StoreData(myMsg->payload[0]);
					closeCount = 0;
				}
				else if(avilableSockets[sckID].state == SHUTDOWN){
					call TCPSocket.StoreData(myMsg->payload[0]);
					closeCount = 0;
				}
				else{
					avilableSockets[sckID].destAddr = destAddr;
					createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
					call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					call TCPManager.freeSocket(&avilableSockets[sckID]);
				}
				//Same
			break;
			case TRANSPORT_TYPE_SIZE:
			dbg("project3", "Dunno packet\n");
				//Dunno
			break;
			}
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){	
			uint16_t sckID = ports[input->SrcPort].scktID;
			scktListPushBack(&freedSockets, sckID);
			//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
			ports[input->SrcPort].isUsed = FALSE;
			ports[input->SrcPort].scktID = 255;
			call TCPSocket.init(input);
			avilableSockets[ListenID].con--;
			dbg("project3", "Freed Socket\n");
			dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections %d\n", avilableSockets[ListenID].ID, avilableSockets[ListenID].destPort, avilableSockets[ListenID].destAddr, avilableSockets[ListenID].SrcPort, avilableSockets[ListenID].SrcAddr, avilableSockets[ListenID].state, avilableSockets[ListenID].con );	
			//avilableSockets[sckID].state = CLOSED;
	}
	
	command addrPort TCPManager.getConnection(){
		return aPpop_front(&acceptBuffer);
		}


	event void ShutDownTimer.fired(){
		dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections %d\n", avilableSockets[CloseMe[0].scktID].ID, avilableSockets[CloseMe[0].scktID].destPort, avilableSockets[CloseMe[0].scktID].destAddr, avilableSockets[CloseMe[0].scktID].SrcPort, avilableSockets[CloseMe[0].scktID].SrcAddr, avilableSockets[CloseMe[0].scktID].state, avilableSockets[CloseMe[0].scktID].con );	
		dbg("project3", "HERE I AM\n");
		if(closeCount == 0){
			closeCount = 1;	
		}
		else{
			
			//call TCPManager.freeSocket(&avilableSockets[CloseMe[0].scktID]);
			call ShutDownTimer.stop();
		}
		// TODO Auto-generated method stub
	}

	event void CloseTimer.fired(){
	
		// TODO Auto-generated method stub
	}
}
