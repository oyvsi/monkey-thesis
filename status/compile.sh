#!/bin/bash

FILENAMES=(status1 status2 status3 status4 status5 status6)


for i in ${FILENAMES[@]}
do
	pdflatex ${i}
#	echo $i
	cp $i.pdf /var/www/
	
done
