/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   Apr 28 2012
 * 
 */ 

#include <Timer.h>
#include "packet.h"

configuration NodeC{
}
implementation {
	components MainC;
	components Node;
	components RandomC as Random;
	
	components new TimerMilliC() as pingTimeoutTimer;
	
	components ActiveMessageC;
	components new AMSenderC(6);
	components new AMReceiverC(6);
	//James Added
	components new TimerMilliC() as NeighborDiscoveryTimer;
	components new TimerMilliC() as LinkstateTimer;
	components new TimerMilliC() as sendDelay;
	Node -> MainC.Boot;
	//Project 3 Additions
	//components NodeC as App; // The main component
	components serverC as ALServer;
	components new TimerMilliC() as ServerTimer;
	components new TimerMilliC() as ServerWorkerTimer;
	
	components TCPManagerC as TCPManager;
	components TCPSocketC as ALSocket;
	
	components new TimerMilliC() as TCPClosingTimer;
	components new TimerMilliC() as TCPShutdownTimer;
	components new TimerMilliC() as ConnectTimer;
	components new TimerMilliC() as ClientConnectTimer;
	components new TimerMilliC() as ReTransmit;
	components new TimerMilliC() as AckRend;
	components new TimerMilliC() as SendReTransmit;
	
	components clientC as ALClient;
	components new TimerMilliC() as ClientTimer;


	//Will finish Later
	Node.ALServer -> ALServer;
	//App.ALServer -> ALServer;
	ALServer.ServerTimer -> ServerTimer;
	ALServer.WorkerTimer -> ServerWorkerTimer;
	ALServer.TCPSocket -> ALSocket;
	ALServer.Random->Random;
	ALServer.TCPManager->TCPManager;
	
	Node.ALClient -> ALClient;
	
	ALClient.Random->Random;
	ALClient.TCPSocket -> ALSocket;
	ALClient.ClientTimer -> ClientTimer;
	ALClient.TCPManager -> TCPManager;
	
	
	//Timers
	Node.pingTimeoutTimer->pingTimeoutTimer;
	
	Node.Random -> Random;
	
	Node.Packet -> AMSenderC;
	Node.AMPacket -> AMSenderC;
	Node.AMSend -> AMSenderC;
	Node.AMControl -> ActiveMessageC;
	
	Node.Receive -> AMReceiverC;
	//James Added
	Node.LinkstateTimer -> LinkstateTimer;
	Node.NeighborDiscoveryTimer -> NeighborDiscoveryTimer;
	Node.sendDelay -> sendDelay;
	Node.TCPManager -> TCPManager;
	Node.ALSocket -> ALSocket;
	TCPManager.node->Node;
	ALSocket.TCPManager -> TCPManager;
	TCPManager.TCPSocket -> ALSocket;
	ALSocket.node -> Node;
	
	
	TCPManager.CloseTimer -> TCPClosingTimer;
	TCPManager.ShutDownTimer -> TCPShutdownTimer;
	TCPManager.Random -> Random;
	TCPManager.ConnectTimer ->ConnectTimer;
	ALSocket.Random -> Random;
	ALSocket.ClientConnectTimer -> ClientConnectTimer;
	ALSocket.ReTransmitTimer -> ReTransmit;
	TCPManager.ReTransmit -> SendReTransmit;
	TCPManager.AckResent -> AckRend;
}
