#!/bin/bash

for metric in delay count
do
	for ac in VI VO BE BK
	do
		for file in `ls ../simulations/results/*.vec`
		do
			perl ../simulations/results/opp_vec2csv_v2.pl -A repetition -A experiment -F $metric$ac:vector $file >> raw.tsv
		done
		# Remove duplicate headers
		wc -l raw.tsv
		awk '!a[$0]++' raw.tsv > $metric$ac.tsv 
		wc -l $metric$ac.tsv
		rm raw.tsv
	done
done
for file in `ls ../simulations/results/*.sca`
do
	perl ../simulations/results/opp_sca2csv.pl \
		SentPackets SentPacketsVO SentPacketsVI SentPacketsBE SentPacketsBK \
		SlotsBackoff SlotsBackoffVO SlotsBackoffVI SlotsBackoffBE SlotsBackoffBK \
		-f $file > `basename $file`.tsv
done
