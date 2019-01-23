#!/bin/bash
echo "running test 4 testnet - Send batches of transaction"
#default version
if [ -z "$1" ];
then VER="1.4.2.3";
else VER=$1;
fi

#default port
if [ -z "$2" ];
then PORT="14700";
else PORT=$2;
fi

bash start_and_stop_a_node.sh $VER $PORT true false 1 ../put_file.py true

