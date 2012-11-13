#include "TCPSocketAL.h"
#include "transport.h"
#include "dataStructures/addrPort.h"

module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
	uses interface TCPManager<TCPSocketAL, addrPort>;
	uses interface node<TCPSocketAL>;
}
implementation{	
	transport sendTCP;
	uint16_t seqNum = 0;
	transport sendTCP;
	addrPort Pair;
	
	async command void TCPSocket.init(TCPSocketAL *input){		
		input->destPort = 0;
		input->destAddr = 0;
		input->SrcPort = 0;
		input->SrcAddr = 0;
		input->state = CLOSED;
		input->maxCon = 0;
		input->pendCon = 0;
		input->con = 0;
		input->RWS = 99;
		input->SWS = 99;	
		input->ID = -1;			
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
		
		if((input->pendCon > 0) && !(input->pendCon > input->maxCon)){
			//dbg("serverAL", "Creating new Socket -  Accepting connection\n");
			output = call TCPManager.socket();
			output->SrcAddr = input->SrcAddr; 
			output->SrcPort = call TCPManager.portCheck(output->SrcPort, output->ID);
			if(output->SrcPort == -1){
				return -1;
			}
			destAddrPort = call TCPManager.getConnection();
			output->destPort = destAddrPort.destPort;
			output->destAddr = destAddrPort.addr;
			output->state = ESTABLISHED;
			input->pendCon--;
			input->con++;
			createTransport(&sendTCP,  output->SrcPort, output->destPort, TRANSPORT_ACK, 0, seqNum++, NULL, 0);
			call node.TCPPacket(&sendTCP, output);
		}
		else{
			//dbg("serverAL", "Unable to create new Socket -  declining connection\n");
			return -1;
		}
		//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections: %d\n", input->ID, input->destPort, input->destAddr, input->SrcPort, input->SrcAddr, input->state, input->pendCon);
		dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d\n", output->ID, output->destPort, output->destAddr, output->SrcPort, output->SrcAddr, output->state);
		//Somehow check if those two are correct?? so just a check
		return 1;
	}	

	//The active open
	async command uint8_t TCPSocket.connect(TCPSocketAL *input, uint16_t destAddr, uint8_t destPort){
		input->destAddr = destAddr;
		input->destPort = destPort;
		dbg("project3", "Sending SYN to destAddr %d destPort %d \n", destAddr, destPort);
		createTransport(&sendTCP, input->SrcPort, destPort, TRANSPORT_SYN, 0, seqNum++, NULL, 0);
		call node.TCPPacket(&sendTCP, input);
		input->state = SYN_SENT;
		return TRUE;
	}

	async command uint8_t TCPSocket.close(TCPSocketAL *input){
		input->state = CLOSING;
		createTransport(&sendTCP, input->SrcPort, input->destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
		call node.TCPPacket(&sendTCP, input);
		//Server goes and sends back a FIN + ACK, saying the server has release all information
		//make sure final FIN has arrived than put state to close
		return 1;
	}

	async command uint8_t TCPSocket.release(TCPSocketAL *input){
		//Somehow release all related data to that connection, purge buffer?
		input->state = SHUTDOWN;
		return -1;
	}

	async command int16_t TCPSocket.read(TCPSocketAL *input, uint8_t *readBuffer, uint16_t pos, uint16_t len){
		//This is where sliding window will occur
		
		return -1;
	}

	async command int16_t TCPSocket.write(TCPSocketAL *input, uint8_t *writeBuffer, uint16_t pos, uint16_t len){
		//Sliding window stuff...
	
		return -1;
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
			*output = *input;
			
			
	}
}
