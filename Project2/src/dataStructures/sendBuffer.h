#ifndef SEND_BUFFER_H
#define SEND_BUFFER_H
#include "transport.h"

typedef struct sendBuff{
	transport TCPPack;
	uint8_t seq;
}sendBuff;


#endif /* SEND_BUFFER_H */
