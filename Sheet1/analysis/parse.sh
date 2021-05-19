#!/bin/bash

for BI in 1 .5 .1 # Beacon intervals
do
	for RC in 25 50 100 # RSU count
	do
	
		scavetool export ../simulations/results/*.sca \
			-f "(name(totalBusyTime) OR name(TotalLostPackets)) AND itervar:rsuCount($RC) AND itervar:beaconInterval($BI)" \
			-o ${RC}_${BI}_.csv 
	done
done
