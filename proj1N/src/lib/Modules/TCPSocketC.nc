#include "TCPSocketAL.h"
#include "ports.h"
#include "transport.h"


module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
}
implementation{	
	//Port 0 is reserved for something....to search for an available port.
	port ports[TRANSPORT_MAX_PORT+1];
	void initports(){
		uint8_t i = 0;
		for(i = 1; i < TRANSPORT_MAX_PORT+1; i++){
			ports[i].isUsed = FALSE;
		}
	}
	
	async command void TCPSocket.init(TCPSocketAL *input){
		input->destPort = -1;
		input->destAddr = -1;
		input->SrcPort = -1;
		input->SrcAddr = TOS_NODE_ID; //current socket at this host
		input->state = CLOSED;
		
	}
	
	async command uint8_t TCPSocket.bind(TCPSocketAL *input, uint8_t localPort, uint16_t address){
		if((localPort > 255) || (ports[localPort].isUsed == TRUE)){
			dbg("project3", "Attempted Bind at localPort %d not valid", localPort);
			return -1;
			}
		if(localPort == 0){
			uint8_t i = 1;
			while(ports[i].isUsed){
				i++;
			}
			input->SrcPort = i;
			ports[i].isUsed = TRUE;
		}
		else{
			input->SrcPort = localPort;
			ports[localPort].isUsed == TRUE;
		}
		input->SrcAddr = address;
		//Maybe still missing stuff, I believe that if you can't bind, than drop all data
		return TRUE;
	}
	
	//the passive open
	//backlog is the amount of max connections;
	async command uint8_t TCPSocket.listen(TCPSocketAL *input, uint8_t backlog){
		//Wait for a syn
		//Once recieved syn, send syn+ack
		input->state = LISTEN;
		//after that change state to ESTABLISHED
		return -1;
	}
	
	async command uint8_t TCPSocket.accept(TCPSocketAL *input, TCPSocketAL *output){
		input->destPort = output->SrcPort;
		input->destAddr = output->SrcAddr;
		//Somehow check if those two are correct?? so just a check
		input->state = ESTABLISHED;
		return -1;
	}

	//The active open
	async command uint8_t TCPSocket.connect(TCPSocketAL *input, uint16_t destAddr, uint8_t destPort){
		//Am I suppose to send a SYN packet here???? how do I even do that...
			//Should I just somehow link node.nc here and use its functions to send stuff?
		input->state = SYN_SENT;
		//Do I call accept here, to connect them.
		return -1;
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
