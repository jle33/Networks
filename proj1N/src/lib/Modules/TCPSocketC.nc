#include "TCPSocketAL.h"
#include "ports.h"
#include "transport.h"


module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
	uses interface TCPManager<TCPSocketAL, pack>;
	uses interface node<TCPSocketAL>;
}
implementation{	
	//Port 0 is reserved for something....to search for an available port.
	transport sendTCP;
	uint16_t seqNum = 0;
	
	async command void TCPSocket.init(TCPSocketAL *input){		
		input->destPort = 0;
		input->destAddr = 0;
		input->SrcPort = 0;
		input->SrcAddr = 0;
		input->state = CLOSED;
		input->connections = 0;
		input->RWS = 100;
		input->SWS = 100;				
	}
	
	async command uint8_t TCPSocket.bind(TCPSocketAL *input, uint8_t localPort, uint16_t address){
		uint8_t errorMsg = call TCPManager.portCheck(localPort);
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
		input->connections = backlog;
		input->state = LISTEN;
		call TCPManager.storeOntoActiveSocketsList(input);
		
		//dbg("project3", "state %d\n",input->state);
		return 0;
	}
	
	async command uint8_t TCPSocket.accept(TCPSocketAL *input, TCPSocketAL *output){
		output->destPort = input->destPort;
		output->destAddr = input->destAddr;
		output->SrcPort = input->SrcPort;
		output->SrcAddr = input->SrcAddr; 
		//Somehow check if those two are correct?? so just a check
		output->state = ESTABLISHED;
		
		return 1;
	}	

	//The active open
	async command uint8_t TCPSocket.connect(TCPSocketAL *input, uint16_t destAddr, uint8_t destPort){
		input->destAddr = destAddr;
		input->destPort = destPort;
		dbg("project3", "Sending SYN to destAddr %d destPort %d \n", destAddr, destPort);
		createTransport(&sendTCP, input->SrcPort, destPort, TRANSPORT_SYN, 0, seqNum, NULL, 0);
		call node.TCPPacket(&sendTCP, input);
		input->state = SYN_SENT;
		call TCPManager.storeOntoActiveSocketsList(input);
		return TRUE;
	}

	async command uint8_t TCPSocket.close(TCPSocketAL *input){
		//Send FIN packet to say we are closing(client side)
		input->state = CLOSING;
		//Server goes and sends back a FIN + ACK, saying the server has release all information
		//make sure final FIN has arrived than put state to close
		input->state = CLOSED;
		return -1;
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
		
	}
}
