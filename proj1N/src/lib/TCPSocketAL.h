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
	uint8_t SWS;
	uint8_t RWS;
	uint16_t ADWIN;
	uint16_t CWIN;
	uint16_t ID;
	uint8_t Buffdata[128];//Just because I can;
	
	uint8_t LastByteRead;
	uint8_t LastbyteRecv;
	uint8_t NextByteExpected;
	uint8_t ExpectedSeqNum;
	
	
	uint16_t EffectiveWindow;
	uint8_t LastSeqSent;
	uint8_t LastByteAcked;
	/*Insert Variables Here */
}TCPSocketAL;

#endif /* TCP_SOCKET_AL_H */
