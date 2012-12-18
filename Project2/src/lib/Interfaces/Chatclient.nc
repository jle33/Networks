interface Chatclient<val_t>{
	command void init(val_t *);
	command void SetUserName(uint8_t* username);
	command void SetSrcPort(uint8_t srcPort);
	command void SetMsg(uint8_t* msg);
	command void setList(uint8_t* list);
	command uint8_t* GetUserName();
}
