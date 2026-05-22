#!/bin/bash
set -x
dir_name=/opt/app/poject
mkdir -p $dir_name
cd $dir_name
pwd
ls -lrt $dir_name/../../
chmod 750 $dir_name/../../app
touch text.txt && echo "this is demo file" >> text.txt
cat "text.txt"

echo $2
