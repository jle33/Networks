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
#include "dataStructures/UserNames.h"
#include "stdio.h"
#include "stdlib.h"

module ChatserverC{
	uses{
		interface TCPSocket<TCPSocketAL>;
		interface Timer<TMilli> as ChatServerTimer;
		interface Timer<TMilli> as ChatWorkerTimer;

		interface Random;
		interface TCPManager<TCPSocketAL,addrPort>;
	}
	provides{
		interface Chatserver<TCPSocketAL>;
		interface ChatserverWorker<serverWorkerAL, TCPSocketAL>;
	}
}
implementation{
	//Local Variables Variables
	serverAL mServer;	
	serverWorkerList workers;
	
	UserName userlist[5];
	uint8_t ldex = 0;
	uint8_t prev = 0;
	
	void easyFix(){
		uint8_t i = 0;
		for(i =0; i<5; i++){	
				memset(userlist[i].UserNames, 0, 13);
		}
		
	}
	
	command void Chatserver.init(TCPSocketAL *socket){
		mServer.socket = socket;
		/*dbg("project4", "mServer.socket->seqNum: %d", mServer.socket->seqNum);
		if(mServer.socket->seqNum == 0){
			mServer.socket->seqNum = 2;
		}*/
		//dbg("project4", "WORKADFJASKDJFLASJDF@!!!@$@#KLJ@#KL$J@LK#$J@\n");
		easyFix();
		mServer.numofWorkers=0;	
		call ChatServerTimer.startPeriodic(SERVER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
		call ChatWorkerTimer.startPeriodic(WORKER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	event void ChatServerTimer.fired(){
	
	
		if( call TCPSocket.isClosed(mServer.socket) == FALSE){ // had a ! in front
		 	
			TCPSocketAL connectedSock;
			//Attempt to Establish a Connection
			if(call TCPSocket.accept(mServer.socket, &connectedSock) == TCP_ERRMSG_SUCCESS){
				serverWorkerAL newWorker;	
				//dbg("project3", "Connected SOCKET destport %d destaddr %d, srcport %d, srcaddr %d, state %d ID %d\n", connectedSock.destPort, connectedSock.destAddr, connectedSock.SrcPort, connectedSock.SrcAddr, connectedSock.state, connectedSock.ID  );												
				dbg("serverAL", "serverAL - Connection Accepted.\n");				
				//create a worker.
				call ChatserverWorker.init(&newWorker, &connectedSock);
				newWorker.id= mServer.numofWorkers;
				mServer.numofWorkers++;
				serverWorkerListPushBack(&workers, newWorker);
			}
		}else{
				//Shutdown
			//Socket is closed, shutdown
			dbg("serverAL", "serverAL - Server Shutdown\n" );
			
			call TCPSocket.release( mServer.socket );			
			call ChatWorkerTimer.stop();
			call ChatServerTimer.stop();
		}
	}
	
	event void ChatWorkerTimer.fired(){
		uint16_t i;
		serverWorkerAL *currentWorker;
		
		for(i=0; i<serverWorkerListSize(&workers); i++){
			currentWorker = serverWorkerListGet(&workers, i);
			call ChatserverWorker.execute(currentWorker);
		}		
	}
	

	
	void buffInit2(serverWorkerAL *worker){
		uint8_t i = 0;
		for(i=0; i<SERVER_WORKER_BUFFER_SIZE; i++){
			worker->SendBuffer[i] = 0;
		}
	}
	
	void buffInit(serverWorkerAL *worker){//Also empties
		uint8_t i = 0;
		for(i=0; i<SERVER_WORKER_BUFFER_SIZE; i++){
			worker->buffer[i] = 0;
		}
	}
	//WORKER
	command void ChatserverWorker.init(serverWorkerAL *worker, TCPSocketAL *inputSocket){
		worker->position = 0;
		worker->position2 = 0;
		worker->socket = call TCPManager.socket();
		
		call TCPSocket.copy(inputSocket, worker->socket);
		
		//dbg("project3", "After Copy destport %d destaddr %d, srcport %d, srcaddr %d, state %d ID %d\n",  worker->socket->destPort, worker->socket->destAddr, worker->socket->SrcPort, worker->socket->SrcAddr, worker->socket->state, worker->socket->ID  );												
		//dbg("project4", "pos 2: %d\n", worker->position2);
		//worker->socket->addr, worker->socket->destAddr);		
		dbg("serverAL", "serverAL - Worker Intilized\n");
		buffInit(worker);
		buffInit2(worker);
		
	}
	
	uint8_t getUser(uint8_t port){
		uint8_t index;
		for(index = 0; index < 5; index++){
			if(userlist[index].port == port){ 
				return index;
			}
		}
		return -1;
	}
	
	command void ChatserverWorker.execute(serverWorkerAL *worker){
		if(call TCPSocket.isClosed( (worker->socket) )  == FALSE){
			uint16_t bufferIndex, length, count, jk;
			uint8_t proIndex = 0;
			uint8_t kj = 0;
			uint8_t temp = 0;
			uint8_t Last = 0;
			//Write stuff!!!
			uint16_t bufferIndex2 = 0, len2 = 0, count2;
			uint8_t Origin = 0;
			uint8_t trigger = 0;
			
			//Write stuff!!!
		//	dbg("project4", "BufferIndex2 : %d , len2: %d, position %d\n", bufferIndex2, len2, worker->position2);
			bufferIndex = (worker->position) % SERVER_WORKER_BUFFER_SIZE + (worker->position/ SERVER_WORKER_BUFFER_SIZE) + 1;
			bufferIndex2 = (worker->position2);
			length = SERVER_WORKER_BUFFER_SIZE - bufferIndex;			//Amount left on the worker buffer
			//len2 =  SERVER_WORKER_BUFFER_SIZE - bufferIndex2;
		//	dbg("project4", "BufferIndex2 : %d , len2: %d\n", bufferIndex2, len2);
			
			//Should do is when it is reading a hello, it will store the username and port in a hashmap in server at port 41
			count = call TCPSocket.read( (worker->socket), worker->buffer, worker->position% SERVER_WORKER_BUFFER_SIZE, length);
			for(jk = 0; jk < 20; jk++){
				if(worker->buffer[jk] == 0){
					break;
				}
				//dbg("project4", "Inside: %c , Index: %d\n", (uint8_t) worker->buffer[jk], jk);
				if((worker->buffer[jk] == 13) && (worker->buffer[jk+1] == 10)){
					//dbg("project4", "Command Packet found\n");
					proIndex = jk+1;
					//dbg("project4", "size %d\n", proIndex);
					/*for(kj = 0; kj < proIndex; kj++){
						dbg("project4", "worker->buffer[kj] = %c\n", worker->buffer[kj]);
					}*/
					if(worker->buffer[0]=='m' && worker->buffer[1]=='s' && worker->buffer[2] == 'g'){
							uint8_t i = 0;	
							dbg("project4", "msg CMD\n");
							for(i=0; i < 4; i++){
								worker->SendBuffer[i] = worker->buffer[i];
								Last = i;
							}
							Origin = getUser(worker->socket->destPort);
							while(userlist[Origin].UserNames[i-4] != NULL){
								worker->SendBuffer[i] = userlist[Origin].UserNames[i-4];
								//dbg("project4", "In buffer %c\n", worker->SendBuffer[i]);
								i++;
							}
							while((worker->buffer[Last] != 13) && (worker->buffer[Last+1] != 10)){
								worker->SendBuffer[i] = worker->buffer[Last];
								Last++;
								//dbg("project4", "In buffer %c, i = %d\n", worker->SendBuffer[i], i);
								i++;
							}
							worker->SendBuffer[i] = worker->buffer[Last];
							worker->SendBuffer[i+1] = worker->buffer[Last+1];
							//dbg("project4", "%s", worker->SendBuffer);
							len2 = i+2;
						//	dbg("project4", "%d\nc", len2);
							prev = prev + len2;	
							trigger = 1;
					}
					
					if(worker->buffer[0]=='h' && worker->buffer[1]=='e' && worker->buffer[2] == 'l'
						&& worker->buffer[3] == 'l' && worker->buffer[4] == 'o'){
							temp = 6;
							while(worker->buffer[temp] != 0x20){
								userlist[ldex].UserNames[temp-6] = worker->buffer[temp];
								//dbg("project4", "Buffer Has: %c\n",userlist[ldex].UserNames[temp-6] );
								temp++;
							}
							temp++;						
							userlist[ldex].port = worker->socket->destPort;
							
						    //dbg("project4", "Buffer Has: %d\n",userlist[ldex].port );
							ldex++;
							dbg("project4", "hello CMD\n");
					}
					if(worker->buffer[0]=='l' && worker->buffer[1]=='i' && worker->buffer[2] == 's'
						&& worker->buffer[3] == 't' && worker->buffer[4] == 'u' && worker->buffer[5] == 's'
							 && worker->buffer[6] == 'r'){
							 	uint8_t jj = 0;
							dbg("project4", "listusr CMD\n");
							dbg("project4", "listusr %s  %s  %s %s \n", userlist[0].UserNames, userlist[1].UserNames, userlist[2].UserNames, userlist[3].UserNames /*strlen(userlist[4].UserNames)*/);
							//dbg("project4", "listusr %d  %d  %d %d %d\n", sizeof(userlist[0].UserNames), userlist[1].UserNames, userlist[2].UserNames, userlist[3].UserNames, userlist[4].UserNames);
							for(jj = 0; jj < 5; jj++){
							//dbg("project4", "SendBuffer: %s, size: %d\n", worker->SendBuffer, strlen(worker->SendBuffer));
								if(userlist[jj].UserNames[0] != 0){
									memcpy((worker->SendBuffer)+strlen(worker->SendBuffer), userlist[jj].UserNames, strlen(userlist[jj].UserNames));
									
									worker->SendBuffer[strlen(worker->SendBuffer)] = ',';
									worker->SendBuffer[strlen(worker->SendBuffer)] = ' ';
									}
							}
							worker->SendBuffer[strlen(worker->SendBuffer)] = '\r';
							worker->SendBuffer[strlen(worker->SendBuffer)] = '\n';
							dbg("project4", "SendBuffer: %s, size: %d\n", worker->SendBuffer, strlen(worker->SendBuffer));
							prev = prev + strlen(worker->SendBuffer);	
					
					}
					
					//dbg("project4", "Empting buffer, length %d pos %d\n", length, worker->position);
					length = 0;
					worker->position = 0;
					count = 0;
					buffInit(worker);
					break;
				}
			}
			len2 = prev;
			
			
			
			if(count == -1){
				// Socket unable to read, release socket
				dbg("serverAL", "serverAL - Releasing socket\n");
				dbg("serverAL", "Position: %lu\n", worker->position);
				call TCPSocket.release( (worker->socket) );
				
				serverWorkerListRemoveValue(&workers, *worker);
				return;
			}
			if(count > 0 ){
				worker->position+=count;
				return;
			}
			//dbg("project4", "worker->Sendbuffer %d\n", worker->SendBuffer[bufferIndex2]);
			//if(worker->SendBuffer[bufferIndex2] != NULL){
				//dbg("project4", "BufferIndex2 : %d , len2: %d\n", bufferIndex2, len2);
			
			
		
			if(trigger == 1){
				uint8_t myusrs = 0;
				uint8_t i = 0;
				serverWorkerAL *currentWorker;
				
					for(i = 0; i < serverWorkerListSize(&workers); i++){
							currentWorker = serverWorkerListGet(&workers, i);
							dbg("project4", "CALLING %d, currentWorker->socket destport %d\n", i, currentWorker->socket->destPort );
							call TCPSocket.write((currentWorker->socket), worker->SendBuffer, bufferIndex2, len2);	
							//dbg("project4", "%s",worker->SendBuffer);
					}
						
			}
			else{
				if(bufferIndex2 >= len2){
					count2 = 0;
					buffInit2(worker->SendBuffer);
					len2=0;
				}
				count2 = call TCPSocket.write((worker->socket), worker->SendBuffer, bufferIndex2, len2);		
				worker->position2 += count2;
			}
				//if(count2 > 0){
					//dbg("project4", "len2 %d, pos %d\n", len2, count2);
					//worker->position2+=count2;
					//return;
				//}
		//	}
		//	else{
				//dbg("project4", "iscorrect\n");
			//}
			
			
			
			/*
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
			}*/
		}else{
			uint32_t closeTime;
			closeTime = call ChatServerTimer.getNow();
			dbg("serverAL", "Connection Closed:\n");
			dbg("serverAL", "Data Read: %d\n", worker->position);
			dbg("serverAL", "Close Time: %d\n", closeTime);
			//call TCPManager.freeSocket(worker.socket);
			call TCPManager.freeSocket(worker->socket); //The Fix?--James added
			serverWorkerListRemoveValue(&workers, *worker); return;
		}
	}
}
