/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#ifndef SERVER_AL_H
#define SERVER_AL_H
#include "TCPSocketAL.h"


typedef struct serverAL{
	TCPSocketAL *socket;
	uint8_t numofWorkers;
}serverAL;

enum{
	SERVER_WORKER_BUFFER_SIZE = 20 // 128 bytes
};

typedef struct serverWorkerAL{
	TCPSocketAL *socket;
	uint16_t position;
	uint8_t buffer[SERVER_WORKER_BUFFER_SIZE]; //receive buffer?
	uint8_t SendBuffer[128];
	uint16_t position2;
	uint8_t id;
}serverWorkerAL;

enum{
	SERVER_TIMER_PERIOD=500, //500 ms
	WORKER_TIMER_PERIOD=533 //533 ms
};
#endif /* SERVER_AL_H */
