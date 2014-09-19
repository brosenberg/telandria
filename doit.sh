#!/bin/sh
./convert.pl -i raw -o newsite -t template.bootstrap
bash ./push.sh $1
