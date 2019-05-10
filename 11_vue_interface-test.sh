#!/bin/bash
echo "running test vue_interface"

set -e

PORT1=14700
PORT2=13700


# clear
rm -rf db*

rm -rf iri/node1

mkdir -p iri/node1

# start iota
java -jar iri/target/iri-1.5.5.jar --testnet --mwm 1 --walk-validator "NULL" --ledger-validator "NULL" -p ${PORT1} \
                        --udp-receiver-port $((PORT1-100)) --tcp-receiver-port $((PORT1-100)) --db-path "./db1" \
                        --db-log-path "./db1.log" --neighbors "tcp://localhost:$((PORT2-100))" --max-peers 40 --remote \
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
 result=$(curl  -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"192.168.130.101\",\"Attestee\":\"192.168.130.110\",\"Score\":\"1\"}")

  echo $result
  touch res.txt
  echo $result >res.txt
  a=$(awk -F [:,] '{ print $2 }' res.txt)
  if [ $a -eq 1 ];
  then
      echo "AddNode test success"
  else
      echo "Wrong!"
      exit -1
  fi

  result=$(curl  -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"192.168.130.102\",\"Attestee\":\"192.168.130.120\",\"Score\":\"1\"}")
  echo $result >res.txt
  a=$(awk -F [:,] '{ print $2 }' res.txt)
  if [ $a -eq 1 ];
  then
      echo "AddNode test success"
  else
      echo "Wrong!"
  exit -1
  fi


# send request QueryNodes
   nodes=$(curl -X POST http://127.0.0.1:8000/QueryNodes -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"period\":1,\"numRank\":100}")
   echo $nodes
   echo $nodes >res.txt
   b=$(awk -F [:,] '{ print $2 }' res.txt)
   if [ $b -eq 1 ];
     then
         echo "QueryNodes test success"
     else
         echo "Wrong!"
         exit -1
     fi
# stop iota and cli
  #ps -aux | grep "[g]o run main.go" | awk '{print $2}' | xargs kill -9
  ps -aux | grep "[g]o-build" | awk '{print $2}' | xargs kill -9
  ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9

echo "run over"


