/*
 * Author: UCM ANDES Lab
 * Date: 2/23/2012
 * Description: Processes commands and returns an Command ID Number.
 */

#ifndef COMMAND_H
#define COMMAND_H
#include "dataStructures/iterator.h"
 
//Command ID Number
enum{
	CMD_PING = 0,
	CMD_NEIGHBOR_DUMP=1,
	CMD_LINKLIST_DUMP=2,
	CMD_ROUTETABLE_DUMP=3,
	CMD_TEST_CLIENT=4,
	CMD_TEST_SERVER=5,
	CMD_KILL=6,
	CMD_ERROR=66,
	
	CMD_HELLO = 7,
	CMD_MSG = 8,
	CMD_CHATSERVER = 9,
	CMD_LIST = 10
	
};

//Lengths of commands
enum{
	PING_CMD_LENGTH = 11,
	DUMP_NEIGHBOR_LENGTH=7
};


bool isServer(uint8_t *array, uint8_t size){
	if(array[0]==(uint8_t)'c' && array[1]==(uint8_t)'m' && array[2]==(uint8_t)'d' && array[3]==(uint8_t)' '
		&& array[4]==(uint8_t)'s' && array[5]==(uint8_t)'e' && array[6]==(uint8_t)'r' && array[7]==(uint8_t)'v'
		&& array[8]==(uint8_t)'e' && array[9]==(uint8_t)'r'){
			return TRUE;
			}
		
	return FALSE;
	}
	
bool isClient(uint8_t *array, uint8_t size){
	if(array[0]==(uint8_t)'c' && array[1]==(uint8_t)'m' && array[2]==(uint8_t)'d' && array[3]==(uint8_t)' '
		&& array[4]==(uint8_t)'c' && array[5]==(uint8_t)'l' && array[6]==(uint8_t)'i' && array[7]==(uint8_t)'e'
		&& array[8]==(uint8_t)'n' && array[9]==(uint8_t)'t'){
			return TRUE;
			}
		
	return FALSE;
	}

bool isValidCMD(uint8_t *array, uint8_t size){
	if(array[0]==(uint8_t)'c' && array[1]==(uint8_t)'m' && array[2]==(uint8_t)'d' && array[3]==(uint8_t)' ')
		return TRUE;
	return FALSE;
}

bool isKill(uint8_t *array, uint8_t size){
	if(array[4] == 'k' && array[5] == 'i' && array[6] == 'l'
	&& array[7] == 'l'){
		return TRUE;
	}
	return FALSE;
}

bool isPing(uint8_t *array, uint8_t size){
	if(array[4]=='p' && array[5]=='i' &&  array[6]=='n' && array[7]=='g'
	&& array[8]==' ' && array[9]>='0' && array[9]<='9' && array[10]==' ')return TRUE;
	return FALSE;
}

bool ishello(uint8_t *array, uint8_t size){
	if(array[4]=='h' && array[5]=='e' &&  array[6]=='l' && array[7]=='l'
	&& array[8]=='o' && array[9]==' ')return TRUE;
	return FALSE;
}
bool ismsg(uint8_t *array, uint8_t size){
	if(array[4]=='m' && array[5]=='s' &&  array[6]=='g')return TRUE;
	return FALSE;
}
bool islist(uint8_t *array, uint8_t size){
	if(array[4]=='l' && array[5]=='i' &&  array[6]=='s' && array[7]=='t'
	&& array[8]=='u' && array[9]=='s' && array[10]=='r')return TRUE;
	return FALSE;
}
bool isChat(uint8_t *array, uint8_t size){
	if(array[4]=='c' && array[5]=='h' &&  array[6]=='a' && array[7]=='t')return TRUE;
	return FALSE;
}





/*
 * getCmd - processes a string to find out which command is being issued. A Command ID is returned based on the
 * enum declared. Also debugging information is sent to the cmdDebug channel.
 * 
 * @param:
 * 		uint8_t *array = a string held in a byte array
 * 		uint8_t size = size of the above string
 * @return:
 * 		int = Returns one of the above ID Numbers to indicate the type of command.
 */
int getCMD(uint8_t *array, uint8_t size){
	dbg("cmdDebug", "A Command has been Issued.\n");

	
	if(!isValidCMD(array, size)){
		dbg("cmdDebug", "CMD_ERROR: \"%s\"is not a valid command due to formating.\n", array);
		return CMD_ERROR;
	}

	if(isPing(array,size)){
		dbg("cmdDebug", "Command Type: Ping\n");
		return CMD_PING;
	}
	
	if(isKill(array, size)){
		dbg("cmdDebug", "Command Type: Kill Node\n");
		return CMD_KILL;
	}
	
	if(isServer(array, size)){
		dbg("cmdDebug", "CMD_TEST_SERVER\n");
		return CMD_TEST_SERVER;
	}
	
	if(isClient(array, size)){
		dbg("cmdDebug", "CMD_TEST_CLIENT\n");
		return CMD_TEST_CLIENT;
	}
	
	
	if(ishello(array, size)){
		dbg("cmdDebug", "CMD_HELLO\n");
		return CMD_HELLO;
	}
	if(ismsg(array,size)){
		dbg("cmdDebug", "CMD_MSG\n");
		return CMD_MSG;
	}
	if(isChat(array,size)){
		dbg("cmdDebug", "CMD_CHAT\n");
		return CMD_CHATSERVER;
	}
	if(islist(array,size)){
		dbg("cmdDebug", "CMD_LIST\n");
		return CMD_LIST;	
	}
	
	dbg("cmdDebug", "CMD_ERROR: \"%s\" does not match any known commands.\n", array);
	return CMD_ERROR;
}


#endif /* COMMAND_H */