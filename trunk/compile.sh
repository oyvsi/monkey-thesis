#!/bin/bash

FILENAME=rapport



pdflatex $FILENAME
bibtex $FILENAME
pdflatex $FILENAME
pdflatex $FILENAME
cp $FILENAME.pdf /var/www/
