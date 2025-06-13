#!/bin/bash

echo "Enter numbers until zero to sum"

while read -r number;
do

	if [ "$number" -eq 0 ]; then 
		break; 
	fi

	sum=$((sum + number))
done

echo "The sum is" $sum
