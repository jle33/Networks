/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#include "serverAL.h"
#include "TCPSocketAL.h"
#include "serverWorkerList.h"
#include "../packet.h"
#include "dataStructures/addrPort.h"

module serverC{
	uses{
		interface TCPSocket<TCPSocketAL>;
		interface Timer<TMilli> as ServerTimer;
		interface Timer<TMilli> as WorkerTimer;

		interface Random;
		interface TCPManager<TCPSocketAL,addrPort>;
	}
	provides{
		interface server<TCPSocketAL>;
		interface serverWorker<serverWorkerAL, TCPSocketAL>;
	}
}
implementation{
	//Local Variables Variables
	serverAL mServer;	
	serverWorkerList workers;

	command void server.init(TCPSocketAL *socket){
		mServer.socket = socket;
		mServer.numofWorkers=0;	
		call ServerTimer.startPeriodic(SERVER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
		call WorkerTimer.startPeriodic(WORKER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	event void ServerTimer.fired(){
	
	
		if( call TCPSocket.isClosed(mServer.socket) == FALSE){ // had a ! in front
		 	
			TCPSocketAL connectedSock;
			//Attempt to Establish a Connection
			if(call TCPSocket.accept(mServer.socket, &connectedSock) == TCP_ERRMSG_SUCCESS){
				serverWorkerAL newWorker;	
				dbg("project3", "Connected SOCKET destport %d destaddr %d, srcport %d, srcaddr %d, state %d ID %d\n", connectedSock.destPort, connectedSock.destAddr, connectedSock.SrcPort, connectedSock.SrcAddr, connectedSock.state, connectedSock.ID  );												
				dbg("serverAL", "serverAL - Connection Accepted.\n");				
				//create a worker.
				call serverWorker.init(&newWorker, &connectedSock);
				newWorker.id= mServer.numofWorkers;
				mServer.numofWorkers++;
				serverWorkerListPushBack(&workers, newWorker);
			}
		}else{
				//Shutdown
			//Socket is closed, shutdown
			dbg("serverAL", "serverAL - Server Shutdown\n" );
			
			call TCPSocket.release( mServer.socket );			
			call WorkerTimer.stop();
			call ServerTimer.stop();
		}
	}
	
	event void WorkerTimer.fired(){
		uint16_t i;
		serverWorkerAL *currentWorker;
		
		for(i=0; i<serverWorkerListSize(&workers); i++){
			currentWorker = serverWorkerListGet(&workers, i);
			
			call serverWorker.execute(currentWorker);
		}		
	}
	
	
	//WORKER
	command void serverWorker.init(serverWorkerAL *worker, TCPSocketAL *inputSocket){
		worker->position = 0;
		worker->socket = call TCPManager.socket();
		
		call TCPSocket.copy(inputSocket, worker->socket);
		
		dbg("project3", "After Copy destport %d destaddr %d, srcport %d, srcaddr %d, state %d ID %d\n",  worker->socket->destPort, worker->socket->destAddr, worker->socket->SrcPort, worker->socket->SrcAddr, worker->socket->state, worker->socket->ID  );												
		
		//worker->socket->addr, worker->socket->destAddr);		
		dbg("serverAL", "serverAL - Worker Intilized\n");
	}
	
	command void serverWorker.execute(serverWorkerAL *worker){
		if(call TCPSocket.isClosed( (worker->socket) )  == FALSE){
			uint16_t bufferIndex, length, count;
			
			bufferIndex = (worker->position) % SERVER_WORKER_BUFFER_SIZE + (worker->position/ SERVER_WORKER_BUFFER_SIZE) + 1;
			
			length = SERVER_WORKER_BUFFER_SIZE - bufferIndex;			//Amount left on the worker buffer
			count = call TCPSocket.read( (worker->socket), worker->buffer, worker->position% SERVER_WORKER_BUFFER_SIZE, length);

			
			if(count == -1){
				// Socket unable to read, release socket
				dbg("serverAL", "serverAL - Releasing socket\n");
				dbg("serverAL", "Position: %lu\n", worker->position);
				call TCPSocket.release( (worker->socket) );
				
				serverWorkerListRemoveValue(&workers, *worker);
				return;
			}
			
			if(count > 0 ){
				
			
				uint16_t i;
				for(i=0; i<count; i++){
					//dbg_clear("project3", "Worker->buffer %d\t ???: %d\n", worker->buffer[ (i+worker->position)%SERVER_WORKER_BUFFER_SIZE], (0x00FF&(i+bufferIndex))  );
									
				
					if( worker->buffer[ (i+worker->position)%SERVER_WORKER_BUFFER_SIZE] != (0x00FF&(i+bufferIndex))){ // Makes a 16 bit into a byte.(8 bits);
						dbg("serverAL", "Releasing socket\n");
						dbg("serverAL", "Buffer Index: %lu Position: %lu\n", i+bufferIndex, worker->position);
						call TCPSocket.release( (worker->socket) );
						serverWorkerListRemoveValue(&workers, *worker);
						return;
					}
				}
				
				worker->position+= count;
				return;
			}
		}else{
			uint32_t closeTime;
			closeTime = call ServerTimer.getNow();
			dbg("serverAL", "Connection Closed:\n");
			dbg("serverAL", "Data Read: %d\n", worker->position);
			dbg("serverAL", "Close Time: %d\n", closeTime);
			//call TCPManager.freeSocket(worker.socket);
			call TCPManager.freeSocket(worker->socket); //The Fix?--James added
			serverWorkerListRemoveValue(&workers, *worker); return;
		}
	}
}
