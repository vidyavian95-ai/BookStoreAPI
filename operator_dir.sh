#!/bin/bash

echo "Current Process ID: $$"

echo "Background Process ID: $!"

echo "Last Executor Details"

last_executor=$(whoami)

echo "Last Executor is: $last_executor"
echo "Files Modified in Last 7 Days"
find . -mtime -7
echo "Process Details"
ps -ef | grep bash

echo "Business Profit History"
touch profit.txt
cat profit.txt
echo profit.txt