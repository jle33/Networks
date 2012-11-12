interface TCPManager<val_t, val2_t>{
	command void init();
	command val_t *socket();
	command void freeSocket(val_t *);
	command void handlePacket(void *);
	command uint8_t portCheck(uint8_t localPort);
	command void storeOntoActiveSocketsList(val_t*);
	//command void buffer(uint16_t destaddr);
}
