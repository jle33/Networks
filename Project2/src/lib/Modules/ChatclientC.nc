/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#include "TCPSocketAL.h"
#include "clientAL.h"
#include "../packet.h"
#include "dataStructures/addrPort.h"

enum{
	ChatBYTES_TO_SEND = 40
};

module ChatclientC{
	uses{
		interface TCPSocket<TCPSocketAL>;
		
		interface Timer<TMilli> as ChatClientTimer;
		interface Random;
		interface TCPManager<TCPSocketAL,addrPort>;
	}
	provides{
		interface Chatclient<TCPSocketAL>;
	}
}
implementation{
	clientAL mClient;
	
	char UserName[13];
	uint8_t Clport;
	uint8_t sizeOfName = 0;
	bool FirstConnect = 1;//true
	uint8_t prevLen = 0;
	
	char MSG[13];
	uint8_t lengthOfMsg = 0;
	uint8_t newMsg = 0;
	
	char List[11];
	uint8_t listCMD = 0;
	
	//Recieve Buffer
	uint8_t RecieveBuffer[64];
	uint16_t rindex = 0;
	uint8_t rmax = 0;
	//Recieve Buffer
	
	uint8_t len2 = 124;
	
	void rint(){ 
		uint8_t i = 0;
		for(i = 0; i < 64; i++){
			RecieveBuffer[i] = 0;
		}
		rindex = 0;
		rmax = 0;
	}
	
	command void Chatclient.init(TCPSocketAL *socket){
		mClient.socket = socket;
		mClient.startTime = 0;
		mClient.position = 0;
		mClient.position2 = 0;
		mClient.amount=ChatBYTES_TO_SEND;
		rint();
		
			
		call ChatClientTimer.startPeriodic(CLIENT_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	command void Chatclient.SetUserName(uint8_t* usrname){
		uint8_t i = 0;
		do{
			UserName[i] = usrname[i];
			i++;
			sizeOfName = i;
			
		}
		while(usrname[i] != NULL);
		dbg("project4", "Name: %s\n", UserName);
	}
	command uint8_t* Chatclient.GetUserName(){
		return UserName;
	}
	command void Chatclient.SetSrcPort(uint8_t srcPort){
		Clport = srcPort;
	}
	command void Chatclient.SetMsg(uint8_t* msg){
		uint8_t i = 4;
		do{
			MSG[i-4] = msg[i];
			i++;
			lengthOfMsg = (i-4);
		}
		while((i < 13));
		newMsg = 1;
		//dbg("project4", "Payload: %s, length %d\n", MSG, lengthOfMsg);
	}
	command void Chatclient.setList(uint8_t* list){
		uint8_t i = 4;
		
		do{
			List[i-4] = list[i];
			i++;
		}
		while(i<11);
		//dbg("project4", "Format: %s\n", List);
		listCMD = 1;
	}
	
	
	event void ChatClientTimer.fired(){
		if(call TCPSocket.isConnectPending( (mClient.socket) )){
			//dbg("clientAL", "clientAL - Connection Pending...\n");
		}else if(call TCPSocket.isConnected( (mClient.socket) )){
			uint16_t bufferIndex, len, count, count2;
			if(FirstConnect != 2){
				FirstConnect = 0;
			}
			
			if(mClient.startTime == 0){ // First Iteration
				mClient.startTime = call ChatClientTimer.getNow();
				dbg("clientAL", "clientAL - Connection established at time: %lu\n Bytes to be send: %lu\n", mClient.startTime, sizeOfName);
				//dbg("project3", "Socket ID: %d destPort: %d destAddr: %d SrcPort: %d SrdAddr: %d State: %d Connections: %d\n", mClient.socket->ID, mClient.socket->destPort, mClient.socket->destAddr, mClient.socket->SrcPort, mClient.socket->SrcAddr, mClient.socket->state, mClient.socket->pendCon);
				
			}
			
			if(mClient.amount == 0){
				return;
			}
			
			/*
			if(mClient.amount == 0){
				//Finish sending all the bytes.
				uint32_t closeTime;
				closeTime = call ChatClientTimer.getNow();
				
				dbg("clientAL", "clientAL - Sending Completed at time: %lu\n",closeTime);
				dbg("clientAL", "Connection Closing...\n");
				
				call TCPSocket.close( (mClient.socket) );
				return;
			}
			 */
			
			if(FirstConnect == 0){
				uint8_t i = 6;
				mClient.buffer[0] = 'h';
				mClient.buffer[1] = 'e';
				mClient.buffer[2] = 'l';
				mClient.buffer[3] = 'l';
				mClient.buffer[4] = 'o';
				mClient.buffer[5] = 0x20; //dec 32
				FirstConnect = 2;
				while (i < sizeOfName+6){
					
					mClient.buffer[i] = UserName[i-6];
					i++;
					len = i;
				}
				//dbg("project4", "USERNAME: %s\n", mClient.buffer);
				mClient.buffer[i] = 0x20;
				i++;
				mClient.buffer[i] = (char)(((int)'0')+Clport);
				i++;
				mClient.buffer[i] = 0x0d;//dec 13
				i++;
				mClient.buffer[i] = 0x0a;//dec 10
				i++;
				len = i;
				prevLen = len;
			}else{
				uint8_t i = 0;
				uint8_t pos = mClient.position;
				
				for(i = 0; i < lengthOfMsg; i++){
					mClient.buffer[i+pos] = MSG[i];	
				}
				if(newMsg == 1){
					mClient.buffer[i+pos] = 0x0d;
					i++;
					mClient.buffer[i+pos] = 0x0a;
					newMsg = 0;
					lengthOfMsg = lengthOfMsg + 2;
					//dbg("project4", "%s", mClient.buffer);
				}
				prevLen = prevLen + lengthOfMsg;
				lengthOfMsg = 0;
				//dbg("project4", "%s", mClient.buffer);
			}
			
			if(listCMD == 1){
				
				uint8_t i = 0;
				uint8_t pos = mClient.position;
				listCMD = 0;
				
				for(i = 0; i < 7; i++){
					mClient.buffer[i+pos] = List[i];	
				}
				//if(listCMD == 1){
					mClient.buffer[i+pos] =  0x0d;
					i++;
					mClient.buffer[i+pos] = 0x0a;
				//	dbg("project4", "size: %d\n", i+pos); 
					listCMD = 0;
			//	}
				prevLen = prevLen + 9;
				//dbg("project4", "%s", mClient.buffer);
			}
			//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!FIX FOR NOW NEED TO CHANGE!!!!!!!!
			len = prevLen;
			bufferIndex = mClient.position % CLIENTAL_BUFFER_SIZE;
			/*
			bufferIndex = mClient.position % CLIENTAL_BUFFER_SIZE;
			if(bufferIndex == 0){ // Out of data, time to create more.
				uint16_t i, offset;
				
				dbg("clientAL", "clientAL - Creating additional data.\n");
				
				offset = mClient.position/255 + 1; //Offset to remove any 0s from the data.
				for(i=0; i< CLIENTAL_BUFFER_SIZE; i++){
					mClient.buffer[i] = (uint8_t)((mClient.position + i + offset)&0x00FF); //Clears first 8 bits in the 16bit int.
				//	dbg("clientAL", "clientAL - POS: %lu, Data: %hhu \n", i, mClient.buffer[i]);
				}
			}*/
			
			
			//if(RecieveBuffer[rindex] != NULL){
				//dbg("project4", "rindex %d\n", rindex);
				count2 = call TCPSocket.read((mClient.socket), RecieveBuffer, rindex, len2);
				if(count2 > 0){
					bool runme = TRUE;
					uint8_t checkme = 0;
					while(runme){
						if(RecieveBuffer[checkme] == 13 && RecieveBuffer[checkme+1] == 10){
							dbg("project4", "%s\n", RecieveBuffer);
							rint();
							runme = FALSE;
							return;
						}
						checkme++;
						if(checkme >= 20){
							runme = FALSE;
						}
					}
					rindex += count2;
					return;
				}
				
			//}
			/*
			//Which is the min, the number of bytes in the buffer or the total number of bytes to be sent.
			if(CLIENTAL_BUFFER_SIZE - bufferIndex < mClient.amount){
				len = CLIENTAL_BUFFER_SIZE - bufferIndex;
			}else{
				len = mClient.amount;
			}*/
			//dbg("clientAL", "len  %d\n", len);
			
			count = call TCPSocket.write((mClient.socket), mClient.buffer, bufferIndex, len);
			
			if(count == -1){
				//Error, release socket immediately.
				uint32_t endTime;
				
				endTime = call ChatClientTimer.getNow();
				dbg("clientAL", "clientAL - Sending aborted at time %lu\n Position: %lu\n", endTime, mClient.position);
				call TCPSocket.release( (mClient.socket) );
				
				call ChatClientTimer.stop();
				return;
			}
			//dbg("project4", "Count: %d\n", count);
			prevLen -= count;
			mClient.amount -= count;
			//mClient.amount = prevLen;
			mClient.position += count;
		}else if(call TCPSocket.isClosing(mClient.socket)){
			//Debugging statements
			//dbg("clientAL", "clientAL ----- CLOSING!\n");
		}else if(call TCPSocket.isClosed( (mClient.socket) )){
			uint32_t endTime = call ChatClientTimer.getNow();
			
			dbg("clientAL", "clientAL - Conection Closed at time: %lu \n Bytes sent: %lu\n Time Elapsed: %lu\n Bytes per Second %lu\n",
			endTime, mClient.position, (endTime - mClient.startTime), (mClient.position * 1000 / (endTime - mClient.startTime)) );
			call TCPSocket.release(mClient.socket);
			call ChatClientTimer.stop();
			return;
		}
	}	
}
