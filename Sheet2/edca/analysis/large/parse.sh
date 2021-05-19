#!/bin/bash

for file in `ls ../../simulations/results/large/*.vec`
do
	echo $file
	perl ../../simulations/results/opp_vec2csv_v2.pl \
		-A repetition \
		-A experiment \
		-A measurement \
		-F delayVO:vector \
		-F delayVI:vector \
		-F delayBE:vector \
		-F delayBK:vector \
		-F countVO:vector \
		-F countVI:vector \
		-F countBE:vector \
		-F countBK:vector $file >> raw.tsv
done
# Remove duplicate headers
wc -l raw.tsv
awk '!a[$0]++' raw.tsv > out.tsv 
wc -l out.tsv
rm raw.tsv

for file in `ls ../../simulations/results/large/*.sca`
do
	perl ../../simulations/results/opp_sca2csv.pl \
		SentPackets SentPacketsVO SentPacketsVI SentPacketsBE SentPacketsBK \
		SlotsBackoff SlotsBackoffVO SlotsBackoffVI SlotsBackoffBE SlotsBackoffBK \
		-f $file > `basename $file`.tsv
done
