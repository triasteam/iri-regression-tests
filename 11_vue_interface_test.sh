#!/bin/bash
echo "running test vue_interface"

set -e

PORT1=14700

# clear
rm -rf db*

mkdir -p iri/node1

# start iota
java -jar iri/target/iri-1.5.5.jar --testnet --mwm 1 --walk-validator "NULL" --ledger-validator "NULL" -p ${PORT1} \
                        --udp-receiver-port $((PORT1-100)) --tcp-receiver-port $((PORT1-100)) --db-path "./db1" \
                        --db-log-path "./db1.log" --max-peers 40 --remote \
                        --enable-streaming-graph --entrypoint-selector-algorithm "KATZ" --tip-sel-algo "CONFLUX" \
                        --ipfs-txns false --batch-txns --weight-calculation-algorithm "IN_MEM" \
                        &>  iri/node1/iri.log &
sleep 1
echo "iota install success"
# run main.go
cd  iri/scripts/front_end/server
go get -d -v ./...
sleep 1
go run main.go &
sleep 2
echo "go install success"
sleep 2

# send request AddNode
#
ip_random1=100
ip_random2=10
for ((i=1;i<=3;i++));
do
    score=$i
    attester=$((ip_random1 + i))
    attestee=$((i * ip_random2 + ip_random1))
    result=$(curl -s -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"192.168.130.${attester}\",\"Attestee\":\"192.168.130.${attestee}\",\"Score\":\"${score}\"}")
    code1=$(echo $result | sed -e 's/[{}]/''/g' | sed s/\"//g | awk -v RS=',' -F: '$1=="Code"{print $2}')
    if [ $code1 -eq 1 ];
    then
        echo "AddNode test${i} success"
    else
        echo "Wrong!"
        echo $result
        exit -1
    fi
done

# send request QueryNodes
nodes=$(curl -s -X POST http://127.0.0.1:8000/QueryNodes -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"period\":1,\"numRank\":100}")
code2=$(echo $nodes | sed -e 's/[{}]/''/g' | sed s/\"//g | awk -v RS=',' -F: '$1=="Code"{print $2}')
    if [ $code2 -eq 1 ];
    then
        echo "QueryNodes test success"
    else
        echo "Wrong!"
        echo $nodes
        exit -1
    fi
# stop iota and cli
ps -aux | grep "[g]o-build" | awk '{print $2}' | xargs kill -9
ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9

sleep 1
# return iri dir
cd ../../../../

echo "run over"


