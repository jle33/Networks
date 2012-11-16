interface TCPManager<val_t, val2_t>{
	command void init();
	command val_t *socket();
	command void freeSocket(val_t *);
	command void handlePacket(void *, uint16_t);
	command uint8_t portCheck(uint8_t localPort, uint16_t scktID);
	command void storeOntoActiveSocketsList(val_t*);
	command val2_t getConnection();
	command uint8_t getPort();
	//command void buffer(uint16_t destaddr);
}
