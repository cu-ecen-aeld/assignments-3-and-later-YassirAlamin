#!/bin/sh

writefile=$1
writestr=$2

if [ $# != 2 ]
then
	echo "Input prameter error"
	exit 1
fi

path=$(dirname $writefile)
mkdir -p $path

echo $writestr > $writefile

if [ ! -f $writefile ] 
then
	echo "File name Error"
	exit 1
fi


if [ ! -e $writefile ]
then
	echo "file can not created"
	exit 1
fi
