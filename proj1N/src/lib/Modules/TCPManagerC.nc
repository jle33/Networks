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
	uses interface node<TCPSocketAL, transport>;
	uses interface Timer<TMilli> as CloseTimer;
	uses interface Timer<TMilli> as ShutDownTimer;
	uses interface Timer<TMilli> as ConnectTimer;
	uses interface Timer<TMilli> as ReTransmit;
	uses interface Timer<TMilli> as AckResent;
	uses interface Random;
}
implementation{
	TCPSocketAL avilableSockets[TRANSPORT_MAX_PORT];
	port ports[TRANSPORT_MAX_PORT];
	transport sendTCP;
	
	
	uint8_t scktID;	//Need
	scktlist freedSockets; //Need
	aPlist acceptBuffer; //Need
	addrPort Pairs; // Need
	uint8_t ListenID;
	PendClose CloseMe[5];
	uint8_t closeCount = 0;
	
	//TCPSocketAL tempSocket;
	uint8_t GlobalConnectID;
	bool pendingConnection = FALSE;
	transport tempPack;
	TCPSocketAL tempAckSock;
	
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
		
	command TCPSocketAL TCPManager.requestSoc(uint8_t portd){
		return  avilableSockets[ports[portd].scktID];
		
	}
	
	command void TCPManager.init(){
		PendCloseInt();
		aPListInit(&acceptBuffer);
		scktListInit(&freedSockets);
		initSockets();
		initPorts();
		scktID = 0;
		call TCPSocket.IntBuff();
	}
	command uint8_t TCPManager.getPort(){
			uint8_t i = 1;
			while(ports[i].isUsed == TRUE){
				i++;
				if(i > 255){
					dbg("project3", "No Ports Avaliable\n");
					return -1;
				}
			}
			return i;
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
		return &avilableSockets[temp];
	}
	
	command void TCPManager.handlePacket(void *payload, uint16_t destAddr){
		transport* myMsg = (transport*) payload;
		uint16_t sckID = ports[myMsg->destPort].scktID;
		printTransport(myMsg);
		switch(myMsg->type){
			case TRANSPORT_SYN:
				switch(avilableSockets[ports[myMsg->destPort].scktID].state){
					case LISTEN:
						ListenID = sckID;
						Pairs.addr = destAddr;
						Pairs.destPort = myMsg->srcPort;
						if(pendingConnection == TRUE){
							
						}
						else if(aPListContains(&acceptBuffer, Pairs.addr , Pairs.destPort) == FALSE){
							pendingConnection = TRUE;
							aPListPushBack(&acceptBuffer, Pairs);
							avilableSockets[sckID].pendCon++;
						}
					break;	
					case CLOSED:
						dbg("project3", "SERVER IS CLOSED, PLEASE TRY AGAIN\n");
						avilableSockets[ports[myMsg->destPort].scktID].destAddr = destAddr;
						createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
						call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					break;
					default: dbg("project3", "SYN State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state);
					break;
				}
			break;
			case TRANSPORT_ACK:
				switch(avilableSockets[sckID].state){
					case SYN_SENT:	
						dbg("project3", "Received ACK now Established\n");
						avilableSockets[sckID].destPort = myMsg->srcPort;
						avilableSockets[sckID].state = ESTABLISHED;	
											
					break;
					case ESTABLISHED: //dbg("project3", "ACK ESTABLISHED\n");
					//	dbg("project3", "LastPacketSent = %d == myMsg->seq = %d\n", avilableSockets[sckID].LastPacketSent+1, myMsg->seq);
						if((avilableSockets[sckID].LastPacketSent+1) == myMsg->seq){
							dbg("project3", "LastPacketSent = %d == myMsg->seq = %d\n", avilableSockets[sckID].LastPacketSent+1, myMsg->seq);
							avilableSockets[sckID].ADWIN = myMsg->window;
							call TCPSocket.emptySendBuffer();
							call TCPSocket.allowWrite();
						}

					break;
					case CLOSING: dbg("project3", "ACK CLOSING\n" );
					
					
					break;
					default: dbg("project3", "DATA State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state); break;
				}
			break;
			case TRANSPORT_FIN:
				switch(avilableSockets[sckID].state){
					case ESTABLISHED: dbg("project3", "FIN ESTABLISHED\n");
						avilableSockets[sckID].state = CLOSED;
					break;
					case CLOSING: dbg("project3", "FIN CLOSING \n");
					break;
					case CLOSED: dbg("project3", "FIN CLOSED \n");
					break;
					
					default: dbg("project3", "State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state); break;
				}

			break;
			case TRANSPORT_DATA:
					switch(avilableSockets[sckID].state){
					case ESTABLISHED: //dbg("project3", "DATA ESTABLISHED\n");
					
						dbg("project3", "ExpectedPacket Seq = %d  ==  ArrivedPacket Seq = %d\n", avilableSockets[sckID].ExpectedPacket, myMsg->seq);
						if(avilableSockets[sckID].ExpectedPacket == myMsg->seq){
							avilableSockets[sckID].ExpectedPacket++;
							avilableSockets[sckID].Buffdata[avilableSockets[sckID].SizeofBuffer] = myMsg->payload[0];
							avilableSockets[sckID].SizeofBuffer++;
							avilableSockets[sckID].ADWIN--;
							createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_ACK, avilableSockets[sckID].ADWIN, (myMsg->seq+1), NULL, 0);
							avilableSockets[sckID].ACKBuffer[avilableSockets[sckID].ACKIndex] = sendTCP;
							avilableSockets[sckID].ACKIndex++;
							if(avilableSockets[sckID].ACKIndex >= 128){
								dbg("project3", "Shit just happened\n");
							}
							call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
							}
						else{
							if(myMsg->seq < avilableSockets[sckID].ExpectedPacket){
								dbg("project3","Retransmitting latest ACK\n");
								avilableSockets[sckID].ACKBuffer[(avilableSockets[sckID].ACKIndex-1)].window = avilableSockets[sckID].ADWIN;
								call node.TCPPacket(&avilableSockets[sckID].ACKBuffer[(avilableSockets[sckID].ACKIndex-1)], &avilableSockets[sckID]);
							}
							dbg("project3", "WTFHAPPANED!@$!@#$!\n");
							}
					break;
					case SHUTDOWN: dbg("project3", "DATA SHUTDOWN\n");
					break;
					
					case CLOSING: dbg("project3", "DATA CLOSING\n");
					break;
					
					default: dbg("project3", "DATA State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state);	
					break;
				}
			break;
			case TRANSPORT_TYPE_SIZE:
			break;
			}
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){	
		
	}
	
	command addrPort TCPManager.getConnection(){
		return aPpop_front(&acceptBuffer);
		}

	
	event void ShutDownTimer.fired(){
	}

	event void CloseTimer.fired(){
		}

	event void ConnectTimer.fired(){
	}
	
	event void ReTransmit.fired(){

	}

	event void AckResent.fired(){
		
	}

}
