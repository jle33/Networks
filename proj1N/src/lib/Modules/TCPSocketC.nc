#include "TCPSocketAL.h"
#include "transport.h"
#include "dataStructures/addrPort.h"
#include "dataStructures/SocketBuffhashmap.h"
#include "serverAL.h"
#include "dataStructures/Bufferiterator.h"
#include "dataStructures/hashmap.h"
#include "listBuffer.h"
#include "sendBuffer.h"

module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
	uses interface TCPManager<TCPSocketAL, addrPort>;
	uses interface node<TCPSocketAL, transport>;
	uses interface Timer<TMilli> as ClientConnectTimer;
	uses interface Timer<TMilli> as ReTransmitTimer;
	uses interface Random;
	
}
implementation{	
	uint8_t seqNum = 0;
	transport sendTCP;
	addrPort Pair;
	uint8_t Buffer[128];//Socket buffer
	uint8_t bufCount = 0;
	TCPSocketAL mySoc;
	uint8_t conAttempt = 0;
	int bufpos = 0;
	//transmap srBuffer; //sender buffer
	transiterator resend;
	//hashmap rBuffer;
	uint8_t keyIn = 0;
	Bufflist sendBuffer;
	sendBuff value;
	transport sendTEMP;
	uint8_t ConnectPort;
	
	command void TCPSocket.IntBuff(){
		//transmapInit(&srBuffer);	
		//hashmapInit(&rBuffer);
		BuffListInit(&sendBuffer);
	}
	
	async command void TCPSocket.StoreData(uint8_t data, uint8_t seq){
		//hashmapInsert(&rBuffer, seq , data);
		//Buffer[bufCount] = data;
		//bufCount++;
	}
	
	async command void TCPSocket.init(TCPSocketAL *input){		
		input->destPort = 0;
		input->destAddr = 0;
		input->SrcPort = 0;
		input->SrcAddr = 0;
		input->state = CLOSED;
		input->maxCon = 0;
		input->pendCon = 0;
		input->con = 0;
		input->ID = -1;	
		
		input->RWS = 128;
		input->SWS = 128;	
	
		input->ADWIN = 128;
		input->CWIN = 0;
		
		input->LastByteRead = 0;
		input->LastbyteRecv = 0;
		input->NextByteExpected = 0;
		input->ExpectedSeqNum = 0;
		
		
		input->LastSeqSent = 0;
		input->LastByteAcked = 0;
		
		//Might be a bug if this function keeps running, unless it creates multiple instances of this, than it's perfect, else call from TCPManager,
		//Also figure out for multiple connections
	}
	
	async command uint8_t TCPSocket.bind(TCPSocketAL *input, uint8_t localPort, uint16_t address){
		uint8_t errorMsg = call TCPManager.portCheck(localPort, input->ID);
		if(errorMsg == -1){
			return -1;
		}
		input->SrcPort = localPort;
		input->SrcAddr = address;
		return 0;
	}
	
	//the passive open
	//backlog is the amount of max connections;
	async command uint8_t TCPSocket.listen(TCPSocketAL *input, uint8_t backlog){
		input->maxCon = backlog;
		input->state = LISTEN;
		return 0;
	}
	
	async command uint8_t TCPSocket.accept(TCPSocketAL *input, TCPSocketAL *output){
		addrPort destAddrPort;
		
		if(input->con >= input->maxCon){
			return -1;
		}
		
		if((input->pendCon > 0) /*&& !(input->pendCon > input->maxCon)*/){
			dbg("serverAL", "Creating new Socket -  Accepting connection\n");
			//output = call TCPManager.socket();
			output->SrcAddr = input->SrcAddr; 
			//output->SrcPort = call TCPManager.portCheck(0, output->ID);
			output->SrcPort = call TCPManager.getPort();
			if(output->SrcPort == -1){
				dbg("project3", "SrcPort Not Good\n");
				return -1;
			}
			destAddrPort = call TCPManager.getConnection();
			output->destPort = destAddrPort.destPort;
			output->destAddr = destAddrPort.addr;
			output->state = ESTABLISHED;
			input->pendCon--;
			input->con++;
			createTransport(&sendTCP,  output->SrcPort, output->destPort, TRANSPORT_ACK, input->ADWIN, 0, NULL, 0);
			call node.TCPPacket(&sendTCP, output);
		}
		else{
			//dbg("serverAL", "Unable to create new Socket -  declining connection\n");
			return -1;
		}
		//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections: %d\n", input->ID, input->destPort, input->destAddr, input->SrcPort, input->SrcAddr, input->state, input->pendCon);
		//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n",output->ID, output->destPort, output->destAddr, output->SrcPort, output->SrcAddr, output->state);
		//Somehow check if those two are correct?? so just a check
		return 1;
	}	

	//The active open
	async command uint8_t TCPSocket.connect(TCPSocketAL *input, uint16_t destAddr, uint8_t destPort){
		input->destAddr = destAddr;
		input->destPort = destPort;
		//dbg("project3", "Sending SYN to destAddr %d destPort %d \n", destAddr, destPort);
		createTransport(&sendTCP, input->SrcPort, destPort, TRANSPORT_SYN, 0, 0, NULL, 0);
		sendTEMP = sendTCP;
		call node.TCPPacket(&sendTCP, input);
		input->state = SYN_SENT;
		ConnectPort = input->SrcPort;
		
		//mySoc = call TCPManager.socket();
		//mySoc->SrcPort = call TCPManager.getPort();
		//call TCPSocket.copy(input, mySoc);
		
		call ClientConnectTimer.startPeriodic(1733);
		return TRUE;
	}

	async command uint8_t TCPSocket.close(TCPSocketAL *input){
		dbg("project3", "Close\n ");
		input->state = CLOSING;
		createTransport(&sendTCP, input->SrcPort, input->destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
		call node.TCPPacket(&sendTCP, input);

		return 1;
	}

	async command uint8_t TCPSocket.release(TCPSocketAL *input){
		//Somehow release all related data to that connection, purge buffer?
		//input->state = SHUTDOWN;
		//input->state = CLOSED;
		return 0;
	}
	
	
	 async command int16_t TCPSocket.read(TCPSocketAL *input, uint8_t *readBuffer, uint16_t pos, uint16_t len){
		uint16_t NextByteRead = 0; //NextNextByteRead
		//dbg("project3", "LastbyteRecv  %d \t NextByteRead   %d\n", input->LastbyteRecv, NextByteRead);
		if(call TCPSocket.isConnected(input) == FALSE){
			return NextByteRead;
		}
		if(input->LastbyteRecv == 0){
			return NextByteRead;
		}
		//dbg("project3", "LastbyteRecv  %d \t NextByteRead   %d\n", input->LastbyteRecv, NextByteRead);
		for(pos; pos < input->LastbyteRecv; pos++){
				readBuffer[pos] = input->Buffdata[input->LastByteRead];
				input->LastByteRead++;
				dbg("data", "Data Being Read: %d\n", readBuffer[pos]);
				NextByteRead++;			
		}
		return NextByteRead;
	}
	
	async command void TCPSocket.checkSendBuff(uint8_t seqAck){
		uint8_t i = 0;
		if(BuffListContains(&sendBuffer, seqAck) == TRUE){
			if(seqAck == 0){
				dbg("project3", "Poping Single\n");
				Spop_front(&sendBuffer);
			}
			else{
				for(i =0; i < (seqAck%128); i++){
						Spop_front(&sendBuffer);
				}
			}
		}

		
	}
	command void TCPSocket.ReTransmitPackets(TCPSocketAL *input){

		uint8_t i = 0;
		uint8_t SizeBuff = BuffListSize(&sendBuffer);
		transport packet;
		sendBuff temp;
		TCPSocketAL toto;
		toto.destAddr = input->destAddr;
		dbg("project3", "Retransmitting packets\n");
		//dbg("project3", "ID: %d, SrcAddr %d, SrcPort %d, DestAddr %d, DestPort %d, State %d\n", input->ID, input->SrcAddr, input->SrcPort, input->destAddr, input->destPort, input->state);
		for(i = 0; i<SizeBuff; i++){
			temp = BuffListGet(&sendBuffer, i);
			packet = temp.TCPPack;
			//dbg("project3", "Retransmitting packets\n");
			//printTransport(&packet);
			call node.TCPPacket(&packet, &toto);
		}
	}
	
	
	command void TCPSocket.MiddleAck(uint8_t seq, TCPSocketAL *input){
		sendBuff temp;
		transport packet;
		uint8_t MaxIndex = NumBuffListContains(&sendBuffer, seq);
		uint8_t i = 0;
		for(i = 0; i < MaxIndex; i++){
			temp = Spop_front(&sendBuffer);
			packet = temp.TCPPack;
			dbg("project3", "MidACK\n");
			printTransport(&packet);
			input->LastByteAcked++;
		}
	}
	
	command void TCPSocket.acked(uint8_t Seq){
		sendBuff temp = Spop_front(&sendBuffer);
		transport packet = temp.TCPPack;
		dbg("project3", "Acked Packet with Seq %d\n", Seq);
		printTransport(&packet);
	}
	
	command void TCPSocket.emptySendBuffer(){
		
		BuffListClear(&sendBuffer);
	}
	
	
	async command int16_t TCPSocket.write(TCPSocketAL *input, uint8_t *writeBuffer, uint16_t pos, uint16_t len){
		uint8_t storage;
		uint8_t allowedPacks = 0;
		uint8_t CurSeq = 0;
		
		if((input->LastSeqSent - input->LastByteAcked) > input->ADWIN){
			return allowedPacks;
		}
		input->EffectiveWindow = input->ADWIN - (input->LastSeqSent - input->LastByteAcked);
		//dbg("project3", "pos: %d    len: %d\n",pos,len);
		//dbg("project3", "ADWIN %d\n", input->ADWIN);
		for(pos; pos < (len+pos); pos++){
			if((allowedPacks < /*input->ADWIN*/ input->EffectiveWindow) && (allowedPacks < len)){
			storage = writeBuffer[pos];
			//dbg("data", "Data Being Sent: %d\n", storage);
			createTransport(&sendTCP, input->SrcPort, input->destPort, TRANSPORT_DATA, 0, seqNum, &storage, sizeof(storage));
			//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrcAddr: %d State: %d Connections: %d\n", input->ID, input->destPort, input->destAddr, input->SrcPort, input->SrcAddr, input->state, input->pendCon);
			value.seq = seqNum;
			
			value.TCPPack = sendTCP;
			BuffListPushBack(&sendBuffer, value);
			call node.TCPPacket(&sendTCP, input);
			input->LastSeqSent = seqNum;
			seqNum++;
			//dbg("project3","HighestSeqSent = %d\n", input->LastSeqSent);
			//call ReTransmitTimer.startPeriodic(1053 + (uint16_t) ((call Random.rand16())%200));
			//count++;
			allowedPacks++;
			}
			else{
				//dbg("project3", "count: %d \t allowedPacks: %d\n", count, allowedPacks);
				return allowedPacks;
			}
		}
		return allowedPacks;
	}

	async command bool TCPSocket.isListening(TCPSocketAL *input){
		if(input->state == LISTEN){
			return TRUE;
			}
		return FALSE;
	}

	async command bool TCPSocket.isConnected(TCPSocketAL *input){
		if(input->state == ESTABLISHED){
			return TRUE;
			}
		return FALSE;
	}

	async command bool TCPSocket.isClosing(TCPSocketAL *input){
		if(input->state == CLOSING){
			return TRUE;
			}
		return FALSE;
	}

	async command bool TCPSocket.isClosed(TCPSocketAL *input){
		if(input->state == CLOSED){
			return TRUE;
			}
		return FALSE;
	}

	async command bool TCPSocket.isConnectPending(TCPSocketAL *input){
		if(input->state == SYN_SENT){
			return TRUE;
			}
		return FALSE;
	}
	
	async command void TCPSocket.copy(TCPSocketAL *input, TCPSocketAL *output){
			
			output->state = input->state;
			output->destAddr = input->destAddr;
			output->destPort = input->destPort;
			output->SrcAddr = input->SrcAddr;
			//dbg("project3","output->ID %d input->SrcPort %d \n", output->ID, input->SrcPort);
			output->SrcPort = call TCPManager.portCheck(input->SrcPort, output->ID);
			
	}

	event void ClientConnectTimer.fired(){
		if(mySoc.state == ESTABLISHED){
			call ClientConnectTimer.stop();
		}
		else if(conAttempt < 5){
			//dbg("project3","Attempting to Establish connection\n");
			mySoc = call TCPManager.requestSoc(ConnectPort);
			conAttempt++;
			//createTransport(&sendTCP, mySoc->SrcPort, mySoc->destPort, TRANSPORT_SYN, 0, 0, NULL, 0);
			call node.TCPPacket(&sendTCP, &mySoc);	
		}
		else{
			dbg("project3", "CLIENT CLOSING\n");
			mySoc.state = CLOSED;
			call ClientConnectTimer.stop();
		}
				
	}

	event void ReTransmitTimer.fired(){
	
		
	}
}
