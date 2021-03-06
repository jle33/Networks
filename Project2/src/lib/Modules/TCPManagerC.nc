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
	aPlist MYconnectedList;
	
	
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
	command bool TCPManager.isConnectedServer(addrPort PA){
		if(aPListContains(&MYconnectedList, PA.addr , PA.destPort) == TRUE){
			return TRUE;
		}
		return FALSE;
	}
	
	command void TCPManager.handlePacket(void *payload, uint16_t destAddr){
		transport* myMsg = (transport*) payload;
		uint16_t sckID = ports[myMsg->destPort].scktID;
		printTransport(myMsg);
		//dbg("project3", "STATE:  %d\n",avilableSockets[ports[myMsg->destPort].scktID].state);
		switch(myMsg->type){
			case TRANSPORT_SYN:
				switch(avilableSockets[ports[myMsg->destPort].scktID].state){
					case LISTEN:
						ListenID = sckID;
						Pairs.addr = destAddr;
						Pairs.destPort = myMsg->srcPort;
						/*if(pendingConnection == TRUE){
							dbg("project3", "What is it doing\n");
						}*/
						

						if(aPListContains(&acceptBuffer, Pairs.destPort , Pairs.addr) == FALSE){
							if(aPListContains(&MYconnectedList, Pairs.destPort , Pairs.addr) == TRUE){
								//dbg("project3", "sending ack to sender\n");
								uint8_t SrcPortc;
								uint8_t destPortc;
								uint8_t conSocID;
								call TCPSocket.getConnectionRe(&SrcPortc, &destPortc, &conSocID);
								createTransport(&sendTCP, SrcPortc, destPortc, TRANSPORT_ACK, avilableSockets[sckID].ADWIN, 1, NULL, 0);
								call node.TCPPacket(&sendTCP, &avilableSockets[conSocID]);
							}
							else{
								addrPort temp = aPListGet(&MYconnectedList, (aPListSize(&MYconnectedList))-1);
								//dbg("project3","SToring! SIZE!: %d\n", aPListSize(&MYconnectedList));
								//dbg("project3", "Values: addr %d, destPort %d\n", temp.addr, temp.destPort);							
								aPListPushBack(&MYconnectedList, Pairs);
								pendingConnection = TRUE;
								aPListPushBack(&acceptBuffer, Pairs);
								avilableSockets[sckID].pendCon++;
							}
						}
						
					break;	
					case CLOSED:
						//dbg("project3", "SERVER IS CLOSED, PLEASE TRY AGAIN\n");
						avilableSockets[ports[myMsg->destPort].scktID].destAddr = destAddr;
						createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 25, 0, NULL, 0);
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
					//		dbg("project3", "LastPacketSent = %d == myMsg->seq = %d\n", avilableSockets[sckID].LastPacketSent+1, myMsg->seq);
							avilableSockets[sckID].ADWIN = myMsg->window;
							avilableSockets[sckID].CurrentSeqAcked = avilableSockets[sckID].LastPacketSent;
							call TCPSocket.emptySendBuffer();
							call TCPSocket.allowWrite();
						}
						else if(myMsg->seq < (avilableSockets[sckID].LastPacketSent)){
							if(myMsg->seq > avilableSockets[sckID].CurrentSeqAcked){
								
								call TCPSocket.ReTransmitPackets(&avilableSockets[sckID],0/*(avilableSockets[sckID].CurrentSeqAcked%10)+1*/);
								avilableSockets[sckID].CurrentSeqAcked++;
								//dbg("project3", "Why you here!!!? %d\n", myMsg->seq);
							}
						}

					break;
					case CLOSING: dbg("project3", "ACK CLOSING\n" );
						if((avilableSockets[sckID].LastPacketSent+1) == myMsg->seq){
						//	dbg("project3", "LastPacketSent = %d == myMsg->seq = %d\t CurrentSeqAcked %d\n", avilableSockets[sckID].LastPacketSent+1, myMsg->seq,avilableSockets[sckID].CurrentSeqAcked );
							avilableSockets[sckID].ADWIN = myMsg->window;
							avilableSockets[sckID].CurrentSeqAcked = avilableSockets[sckID].LastPacketSent;
							call TCPSocket.emptySendBuffer();
							call TCPSocket.allowWrite();
						}
						else if(myMsg->seq < (avilableSockets[sckID].LastPacketSent)){
							if(myMsg->seq > avilableSockets[sckID].CurrentSeqAcked){
								call TCPSocket.ReTransmitPackets(&avilableSockets[sckID], 0/*(avilableSockets[sckID].CurrentSeqAcked%10)+1*/);
								avilableSockets[sckID].CurrentSeqAcked++;
								//dbg("project3", "Why you here!!!? %d\n", myMsg->seq);
							}
						}
						if(avilableSockets[sckID].LastPacketSent == avilableSockets[sckID].CurrentSeqAcked){
							createTransport(&sendTCP, avilableSockets[sckID].SrcPort, avilableSockets[sckID].destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
							call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
							avilableSockets[sckID].state = CLOSED;
						}
					
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
						if(avilableSockets[sckID].LastPacketSent == avilableSockets[sckID].CurrentSeqAcked){
							avilableSockets[sckID].state = CLOSED;
						}
					break;
					case CLOSED: dbg("project3", "FIN CLOSED \n");
						createTransport(&sendTCP, avilableSockets[sckID].SrcPort, avilableSockets[sckID].destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
						call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					break;
					
					default: dbg("project3", "State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state); break;
				}

			break;
			case TRANSPORT_DATA:
					switch(avilableSockets[sckID].state){
					case ESTABLISHED: //dbg("project3", "DATA ESTABLISHED\n");
					
					//	dbg("project3", "ExpectedPacket Seq = %d  ==  ArrivedPacket Seq = %d    LastPacketRead = %d\n", avilableSockets[sckID].ExpectedPacket, myMsg->seq, avilableSockets[sckID].LastPacketRead);
						if(avilableSockets[sckID].ExpectedPacket == myMsg->seq){
							avilableSockets[sckID].ExpectedPacket++;
							avilableSockets[sckID].Buffdata[avilableSockets[sckID].SizeofBuffer] = myMsg->payload[0];
							avilableSockets[sckID].SizeofBuffer++;
							avilableSockets[sckID].ADWIN--;
							createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_ACK, avilableSockets[sckID].ADWIN, (myMsg->seq+1), NULL, 0);
							avilableSockets[sckID].ACKBuffer[avilableSockets[sckID].ACKIndex] = sendTCP;
							avilableSockets[sckID].ACKIndex++;
							if(avilableSockets[sckID].ACKIndex >= 128){
								dbg("project3", "Not good happened\n");
							}
							call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
							}
						else{
							if(myMsg->seq >= avilableSockets[sckID].LastPacketRead){
							//	dbg("project3","Retransmitting latest ACK\n");
								avilableSockets[sckID].ACKBuffer[(avilableSockets[sckID].ACKIndex-1)].window = avilableSockets[sckID].ADWIN;
								call node.TCPPacket(&avilableSockets[sckID].ACKBuffer[(avilableSockets[sckID].ACKIndex-1)], &avilableSockets[sckID]);
							}
							//dbg("project3", "WTFHAPPANED!@$!@#$!\n");
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
	
	command bool TCPManager.CheckState(uint8_t ThescktID){
		if(avilableSockets[ThescktID].state == SYN_SENT){
			return TRUE;
		}
		return FALSE;
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
