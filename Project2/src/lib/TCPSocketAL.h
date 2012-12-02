/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#ifndef TCP_SOCKET_AL_H
#define TCP_SOCKET_AL_H
#include "transport.h"
enum TCPSOCKET_STATE{
	CLOSED=0,
	LISTEN=1,
	SYN_SENT=2,
	ESTABLISHED=3,
	SHUTDOWN=4,
	CLOSING=5
};

enum TCPSOCKET_ERR_MSG{
 
	TCP_ERRMSG_SUCCESS = 1
 
};  

//The Socket
typedef struct TCPSocketAL{
	uint8_t destPort;
	uint16_t destAddr; 
	uint8_t SrcPort;//myself
	uint16_t SrcAddr;//myself
	uint8_t state;
	uint8_t pendCon; //PendingConnections
	uint8_t maxCon; //Max number of supported Connections
	uint8_t con;

	uint16_t ADWIN;
	//uint8_t dataRead;
	uint8_t ExpectedPacket;
	uint8_t LastPacketRead;
	uint8_t LastPacketSent;
	uint16_t ID;
	uint8_t SizeofBuffer;
	uint8_t Buffdata[128];//Just because I can;
	uint8_t seqNum;
	uint8_t CurrentSeqAcked;
	
	transport ACKBuffer[128];
	uint8_t ACKIndex;

	/*Insert Variables Here */
}TCPSocketAL;

#endif /* TCP_SOCKET_AL_H */
