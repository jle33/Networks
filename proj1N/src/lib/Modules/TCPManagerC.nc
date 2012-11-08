#include "TCPSocketAL.h"
#include "../packet.h"
#include "transport.h"

module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, pack>;
	uses interface TCPSocket<TCPSocketAL>;	
}
implementation{
	command void TCPManager.init(){

		
	}
	
	command TCPSocketAL *TCPManager.socket(){
		TCPSocketAL *thesocket;
		
		
		return thesocket;
	}
	

	command void TCPManager.handlePacket(void *payload){
		dbg("Project3", "HEY Me, REcieced TCP\n");
		transport* myMsg = (transport*) payload;
		switch(myMsg->type){
			case TRANSPORT_SYN:
			break;
			case TRANSPORT_ACK:
			break;
			case TRANSPORT_FIN:
			break;
			case TRANSPORT_DATA:
			break;
			case TRANSPORT_TYPE_SIZE:
			break;
			}
		
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){	
		//Resetting the socket?
			
	}
}
