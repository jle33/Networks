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
	uses interface Timer<TMilli> as ConnectTimer;
	uses interface Random;
}
implementation{
	TCPSocketAL avilableSockets[TRANSPORT_MAX_PORT];
	port ports[TRANSPORT_MAX_PORT];
	transport sendTCP;

	uint8_t scktID;
	scktlist freedSockets;
	aPlist acceptBuffer;
	addrPort Pairs;
	uint8_t ListenID;
	PendClose CloseMe[5];
	uint8_t closeCount = 0;
	
	uint8_t lastbyteSentSeq = 0;
	
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
		//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", avilableSockets[temp].ID, avilableSockets[temp].destPort, avilableSockets[temp].destAddr, avilableSockets[temp].SrcPort, avilableSockets[temp].SrcAddr, avilableSockets[temp].state );
		return &avilableSockets[temp];
	}
	
	command void TCPManager.handlePacket(void *payload, uint16_t destAddr){
		transport* myMsg = (transport*) payload;
		uint16_t sckID = ports[myMsg->destPort].scktID;
		uint16_t Seq = 0;
		uint16_t ExpectedSeq;
		//printTransport(myMsg);
		switch(myMsg->type){
			case TRANSPORT_SYN:
			//dbg("project3", "SYN packet\n destPort %d  ports.scktID %d ports.isUsed %d\n", myMsg->destPort, ports[myMsg->destPort].scktID, ports[myMsg->destPort].isUsed);
			//dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
				switch(avilableSockets[ports[myMsg->destPort].scktID].state){
					case LISTEN:
						ListenID = sckID;
						Pairs.addr = destAddr;
						Pairs.destPort = myMsg->srcPort;
						if(aPListContains(&acceptBuffer, Pairs.addr , Pairs.destPort) == FALSE){
							aPListPushBack(&acceptBuffer, Pairs);
							avilableSockets[sckID].pendCon++;
						}
						//dbg("project3", "Amount of connections pending: %d\t Amount of connections: %d\n", avilableSockets[sckID].pendCon,avilableSockets[sckID].con);
						//dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
					break;	
					case CLOSED:
						dbg("project3", "SERVER IS CLOSED, PLEASE TRY AGAIN\n");
						avilableSockets[ports[myMsg->destPort].scktID].destAddr = destAddr;
						createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
						call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
					break;
					default: dbg("project3", "State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state);
					break;
				}
			break;
			case TRANSPORT_ACK:
				switch(avilableSockets[sckID].state){
					case SYN_SENT:
						dbg("project3", "Received ACK now Established\n");
						avilableSockets[sckID].destPort = myMsg->srcPort;
						avilableSockets[sckID].state = ESTABLISHED;
					//	dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
						
					break;
					case ESTABLISHED:
						//dbg("project3", "HighestSeqSent = %d\n ",avilableSockets[sckID].LastSeqSent);
						if((avilableSockets[sckID].LastSeqSent + 1) == myMsg->seq){
							call TCPSocket.emptySendBuffer();
							dbg("project3", "ACKED ALL PACKETS\n");
							
						}
						else if((avilableSockets[sckID].LastByteAcked + 1) == myMsg->seq ){
							
						}
						//dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
						//call TCPSocket.checkSendBuff(myMsg->seq);
						//dbg("project3", "ACK for data Expected Seq %d\n", myMsg->seq);
						
						
					break;
					case CLOSING:
					
					break;
					default: dbg("project3", "State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state); break;
				}
			break;
			case TRANSPORT_FIN:
				switch(avilableSockets[sckID].state){
					case ESTABLISHED: dbg("project3", "FIN ESTABLISHED\n");
						
						createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
						call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
						CloseMe[0].scktID = sckID;
						closeCount = 0;
						avilableSockets[sckID].state = CLOSED;
						//call ShutDownTimer.startPeriodic(2534 + (uint16_t) ((call Random.rand16())%200));
					break;
					case CLOSING: dbg("project3", "FIN CLOSING \n");
						//call TCPManager.freeSocket(&avilableSockets[sckID]);
					break;
					case CLOSED: dbg("project3", "FIN CLOSED \n");
						
					break;
					default: dbg("project3", "State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state); break;
				}

			break;
			case TRANSPORT_DATA:
					Seq = myMsg->seq;			
					ExpectedSeq = avilableSockets[sckID].ExpectedSeqNum;
					switch(avilableSockets[sckID].state){
					case ESTABLISHED:
						dbg("project3", "Data Recieved:  %d\n",myMsg->payload[0]);
					
						//dbg("project3", "DATA ESTABLISHED\n");
						//dbg("project3", "destPort %d  sckID %d    ExpectedSeq %d     Seq %d\n",myMsg->destPort, sckID, avilableSockets[sckID].ExpectedSeqNum, Seq);
						if(ExpectedSeq == Seq){
							avilableSockets[sckID].Buffdata[avilableSockets[sckID].NextByteExpected] = myMsg->payload[0];
							dbg("project3", "Storing onto Buffer %d\n",avilableSockets[sckID].Buffdata[avilableSockets[sckID].NextByteExpected] );
							avilableSockets[sckID].LastbyteRecv++;
							//dbg("project3", "LastbyteRecv  %d\n", avilableSockets[sckID].LastbyteRecv);
							avilableSockets[sckID].NextByteExpected = avilableSockets[sckID].LastbyteRecv;
							avilableSockets[sckID].ADWIN = avilableSockets[sckID].RWS - avilableSockets[sckID].LastbyteRecv;
							//dbg("project3", "ADWIN %d\n", 	avilableSockets[sckID].ADWIN);			
							createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_ACK,avilableSockets[sckID].ADWIN, avilableSockets[sckID].ExpectedSeqNum++, NULL, 0);
							call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
						}
						else{
							//dbg("project3" ,"Not expected seqNum Resending seq: %d\n", avilableSockets[sckID].ExpectedSeqNum);
							createTransport(&sendTCP, myMsg->destPort, myMsg->srcPort, TRANSPORT_ACK, avilableSockets[sckID].ADWIN, avilableSockets[sckID].ExpectedSeqNum, NULL, 0);
							call node.TCPPacket(&sendTCP, &avilableSockets[sckID]);
						}
					break;

					default: dbg("project3", "DATA State %d \n", avilableSockets[ports[myMsg->destPort].scktID].state);
					//dbg("project3", "sckID %d Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",sckID ,avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
					//dbg("project3", "Data Recieved:  %d\n",avilableSockets[sckID].Buffdata[avilableSockets[sckID].NextByteExpected] );
					printTransport(myMsg);		
					 break;
				}
			
				//dbg("project3", "Server State = %d     ScktID: %d   InScktID: %d\n", avilableSockets[sckID].state,sckID ,avilableSockets[sckID].ID );
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
			dbg("project3", "FREE SOCKT PART  inputID %d input->srcPort %d  Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",input->ID, input->SrcPort, avilableSockets[sckID].ID, avilableSockets[sckID].destPort, avilableSockets[sckID].destAddr, avilableSockets[sckID].SrcPort, avilableSockets[sckID].SrcAddr, avilableSockets[sckID].state );
			ports[input->SrcPort].isUsed = FALSE;
			ports[input->SrcPort].scktID = 255;
			call TCPSocket.init(input);
			avilableSockets[ListenID].con--;
			dbg("project3", "Freed Socket\n");
			//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections %d\n", avilableSockets[ListenID].ID, avilableSockets[ListenID].destPort, avilableSockets[ListenID].destAddr, avilableSockets[ListenID].SrcPort, avilableSockets[ListenID].SrcAddr, avilableSockets[ListenID].state, avilableSockets[ListenID].con );	
			avilableSockets[sckID].state = CLOSED;
	}
	
	command addrPort TCPManager.getConnection(){
		return aPpop_front(&acceptBuffer);
		}


	
	
	event void ShutDownTimer.fired(){
		dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections %d\n", avilableSockets[CloseMe[0].scktID].ID, avilableSockets[CloseMe[0].scktID].destPort, avilableSockets[CloseMe[0].scktID].destAddr, avilableSockets[CloseMe[0].scktID].SrcPort, avilableSockets[CloseMe[0].scktID].SrcAddr, avilableSockets[CloseMe[0].scktID].state, avilableSockets[CloseMe[0].scktID].con );	
		if(closeCount == 0){
			closeCount = 1;	
		}
		else{
			call TCPManager.freeSocket(&avilableSockets[CloseMe[0].scktID]);
			call ShutDownTimer.stop();
		}
		// TODO Auto-generated method stub
	}

	event void CloseTimer.fired(){
	
		// TODO Auto-generated method stub
	}

	event void ConnectTimer.fired(){
		// TODO Auto-generated method stub
	}
}
