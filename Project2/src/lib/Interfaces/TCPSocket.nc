interface TCPSocket<val_t>{
	async command void StoreData(uint8_t data, uint8_t seq);
	command void IntBuff();
	command void acked(uint8_t Seq);
	async command void checkSendBuff(uint8_t seqCheck);
	command void MiddleAck(uint8_t seq, val_t*);
	command void emptySendBuffer();
	command void ReTransmitPackets(val_t*, uint8_t start);
	async command void init(val_t *input);
	command void allowWrite();
	command void getConnectionRe(uint8_t* SrcPort, uint8_t* destPort, uint8_t* conSocID);
	async command uint8_t bind(val_t *input, uint8_t localPort, uint16_t address);
	
	async command uint8_t listen(val_t *input, uint8_t backlog);
	
	async command uint8_t accept(val_t *input, val_t *output);
	
	async command uint8_t connect(val_t *input, uint16_t destAddr, uint8_t destPort);
	
	async command uint8_t close(val_t *input);
	
	async command uint8_t release(val_t *input);
	
	async command int16_t read(val_t *input, uint8_t *readBuffer, uint16_t pos, uint16_t len);
	
	async command int16_t write(val_t *input, uint8_t *writeBuffer, uint16_t pos, uint16_t len);
	
	//Checks
	async command bool isConnectPending(val_t *input);
	async command bool isConnected(val_t *input);
	async command bool isListening(val_t *input);
	async command bool isClosed(val_t *input);
	async command bool isClosing(val_t *input);
	
	async command void copy(val_t *input, val_t *output);
	
}
