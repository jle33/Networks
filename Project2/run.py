#ANDES Lab - University of California, Merced
#Author: UCM ANDES Lab
#Last Update: 4/28/2011
#! /usr/bin/python
from TOSSIM import *
from packet import *
import sys
import random

t = Tossim([])
r = t.radio()
f = open("topo.txt", "r")
slen = 0

for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))
    slen = 1 + slen
   
# Channels used for debuging
#t.addChannel("genDebug", sys.stdout)
t.addChannel("cmdDebug", sys.stdout)
#t.addChannel("Project1F", sys.stdout)
#t.addChannel("Project1N", sys.stdout)
#t.addChannel("mydebug", sys.stdout)
#t.addChannel("hashmap", sys.stdout)
#t.addChannel("Project2", sys.stdout)
#t.addChannel("Project2D", sys.stdout)
#t.addChannel("Project3", sys.stdout)
#t.addChannel("clientAL", sys.stdout)
#t.addChannel("serverAL", sys.stdout)
#t.addChannel("project3", sys.stdout)
#t.addChannel("error", sys.stdout)
#t.addChannel("transport", sys.stdout)
#t.addChannel("dataRead",sys.stdout)
#t.addChannel("dataWrite", sys.stdout)
t.addChannel("project4", sys.stdout)

noise = open("no_noise.txt", "r")
#noise = open("heavy_noise_30_.txt", "r")

numNodes = 5
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(1, numNodes+1):
       t.getNode(i).addNoiseTraceReading(val)


for i in range(1, numNodes+1):
    print "Creating noise model for ", i;
    t.getNode(i).createNoiseModel()
    
for i in range(1, numNodes+1):
    t.getNode(i).bootAtTime(random.choice(range(1, 250, 1)))

def package(string):
 	ints = []
	for c in string:
		ints.append(ord(c))
	return ints

def run(ticks):
	for i in range(ticks):
		t.runNextEvent()

def runTime(amount):
	time = t.time()
	while time + amount*10000000000 > t.time():
		t.runNextEvent() 

#Create a Command Packet
msg = pack()
msg.set_seq(300)
msg.set_TTL(15)
msg.set_protocol(99)

pkt = t.newPacket()
pkt.setData(msg.data)
pkt.setType(msg.get_amType())

def sendCMD(string):
	args = string.split(' ');
	msg.set_src(int(args[0]));
	msg.set_dest(int(args[1]));
    #msg.set_protocol(int(args[2]));
	payload=args[2];
	for i in range(3, len(args)):
		payload= payload + ' '+ args[i]
	
	msg.setString_payload(payload)
	
	pkt.setData(msg.data)
	pkt.setDestination(int(args[1]))
	
	#print "Delivering!"
	pkt.deliver(int(args[1]), t.time()+5)
	runTime(2);


#James Added
#print("----------------Flood Starting-------------------");
#should send a message to node 5, but also flood all other nodes along the way.
#sendCMD is a packetInjection, so will work one way.
#sendCMD("1 1 Run now!")
#sendCMD("1 5 Hello BRO!")

#runTime(1000)
#sendCMD("6 6 hello");
#sendCMD("6 6 cmd ping 3 Hello");
#sendCMD("1 3 hello")
#sendCMD("3 3 cmd server 29")
#sendCMD("1 1 cmd client 99 29 3")
runTime(200)
print("-------------------CHAT SERVER----------------------")
sendCMD("1 1 cmd chat 41") #starts up the chat server
runTime(200)
sendCMD("3 3 cmd hello james 3\r\n")
runTime(200)
sendCMD("4 4 cmd hello adria 1\r\n")
sendCMD("5 5 cmd hello nWang 2\r\n")
runTime(600)
#sendCMD("4 4 cmd hello jaml3 2\r\n")
#sendCMD("2 2 cmd hello fooba 7\r\n")
sendCMD("3 3 cmd msg Hello!\r\n")
runTime(2000)
sendCMD("3 3 cmd listusr\r\n")
runTime(200)


#sendCMD("4 4 cmd client 98 29 3")
#sendCMD("3 3 cmd client 99 29 4")


