#!/bin/sh

filedir=$1
searchstr=$2


if [ $# != 2 ]
then
	echo "Input Parameters Error"
	exit 1
fi

if [ ! -d $filedir  ]; then
	echo "Parameter 2 is not a directory"
	exit 1
fi

# Matches lines
Y=$(grep -r $searchstr $filedir | wc -l)

# Number of files 
X=$(grep -rl $searchstr $filedir | wc -l)

echo "\nThe number of files are" $X "and the number of matching lines are" $Y

