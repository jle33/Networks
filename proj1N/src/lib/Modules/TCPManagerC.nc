#include "TCPSocketAL.h"
#include "../packet.h"
#include "transport.h"
#include "Buffer.h"	
#include "ports.h"

module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, pack>;
	uses interface TCPSocket<TCPSocketAL>;	
	uses interface node<TCPSocketAL>;
}
implementation{
	TCPSocketAL avilableSockets[TRANSPORT_MAX_PORT];
	port ports[TRANSPORT_MAX_PORT];
	transport sendTCP;
	uint16_t ExpectedseqNum;
	uint8_t scktID;

	void initSockets(){
		int i = 0;
		for (i = 0; i < TRANSPORT_MAX_PORT; i++){
			call TCPSocket.init(&avilableSockets[i]);
		}
	}
	
	void initPorts(){
		int i = 0;
		for(i = 0; i < TRANSPORT_MAX_PORT; i++){
			ports[i].isUsed = FALSE;
		}
	}
	
	uint8_t getPort(){
		uint8_t freePort = 0;
		freePort = call TCPManager.portCheck(freePort);
		return freePort;
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
		avilableSockets[input->SrcPort] = *input;
		dbg("project3", "SocList :: Socket destPort %d destAddr %d SrcPort %d SrcAddr %d State %d \n", avilableSockets[input->SrcPort].destPort, avilableSockets[input->SrcPort].destAddr, avilableSockets[input->SrcPort].SrcPort, avilableSockets[input->SrcPort].SrcAddr,avilableSockets[input->SrcPort].state );
		//dbg("project3", "SocList :: Socket destPort %d destAddr %d SrcPort %d SrcAddr %d State %d \n", avilableSockets[input->SrcPort]->destPort, avilableSockets[input->SrcPort]->destAddr, avilableSockets[input->SrcPort]->SrcPort, avilableSockets[input->SrcPort]->SrcAddr,avilableSockets[input->SrcPort]->state );	
	}
	
	
	command void TCPManager.init(){
		initSockets();
		initPorts();
		ExpectedseqNum = 1;
		scktID = 0;
	}
	
	command uint8_t TCPManager.portCheck(uint8_t localPort){
		if((localPort > 255) || (ports[localPort].isUsed == TRUE)){
			return -1;
		}
		else if(localPort == 0){
			uint8_t i = 1;
			while(ports[i].isUsed == TRUE){
				i++;
			}
			return i;
			
		}
		return localPort;	
	}
	
	command TCPSocketAL *TCPManager.socket(){
		return &avilableSockets[scktID++];
	}

	command void TCPManager.handlePacket(void *payload){
		transport* myMsg = (transport*) payload;
		switch(myMsg->type){
			case TRANSPORT_SYN:
				dbg("project3", "SYN packet\n");
				if(avilableSockets[myMsg->destPort].state == LISTEN){
					//Doing two way handshake
					uint8_t freePort = getPort();
					dbg("project3", "Two-Way Handshake");
					//call TCPSocket.accept(&avilableSockets[myMsg->srcPort], &avilableSockets[freePort]);
					createTransport(&sendTCP, avilableSockets[freePort].SrcPort, myMsg->srcPort, TRANSPORT_ACK, 0, 0, NULL, 0);
					call node.TCPPacket(&sendTCP, &avilableSockets[freePort]);
				}
				else{
					createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
					call node.TCPPacket(&sendTCP, &avilableSockets[myMsg->srcPort]);
				}
				//call accept
				//send to something based on destPort and destAddr
			break;
			case TRANSPORT_ACK:
				dbg("project3", "ACK packet\n");
				//createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				//call node.TCPPacket(&sendTCP, 1);
				avilableSockets[myMsg->destPort].state = ESTABLISHED;
				//Same
			break;
			case TRANSPORT_FIN:
			dbg("project3", "FIN packet\n");
				//Same
			break;
			case TRANSPORT_DATA:
			dbg("project3", "Data packet\n");
				//Same
			break;
			case TRANSPORT_TYPE_SIZE:
			dbg("project3", "Dunno packet\n");
				//Dunno
			break;
			}
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){	
		//call TCPSocket.release(input);
		//ports[input->SrcPort].isUsed = FALSE;
		//Resetting the socket?
	}

}
