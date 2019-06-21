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

#send request AddNode_1
attester_1=192.168.130.101
attestee_1=192.168.130.110
score_1=1
res_score1=0.649134991926838
res_score2=0.350865008073162
touch result.txt
curl -s -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"${attester_1}\",\"Attestee\":\"${attestee_1}\",\"Score\":\"${score_1}\"}"

#send request QueryNodes
result1=$(curl -s -X POST http://127.0.0.1:8000/QueryNodes -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"period\":1,\"numRank\":100}")

echo $result1
echo $result1 > result.txt
array=($(awk -F '[:,"}]' '{$1="";print $0}' result.txt))

#determine whether to include
function contains()
{
for((i=0;i<${#array[@]};i++))
do
    if [ "${array[$((i))]}" == "$1" ] && [ "${array[$((i += 2))]}" == "$2" ]
    then
        echo "$1 query success"
        break
    elif [ $i == $((${#array[@]} - 1)) ]
        then
        echo "Wrong"
        echo "$1 query failed"
        ps -aux | grep "[g]o-build" | awk '{print $2}' | xargs kill -9
        ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9
        cd ../../../../
        rm -rf iri/node1/iri1.log
        exit -1
    fi
done
}

#test AddNode_1
contains $attester_1 $res_score2
contains $attestee_1 $res_score1

#send request AddNode_2
attester_2=192.168.130.110
attestee_2=192.168.130.112
score_2=2
res_score1=0.350865008073162
res_score2=0.649134991926838
curl -s -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"${attester_2}\",\"Attestee\":\"${attestee_2}\",\"Score\":\"${score_2}\"}"

#send request QueryNodes
result2=$(curl -s -X POST http://127.0.0.1:8000/QueryNodes -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"period\":1,\"numRank\":100}")
echo $result2
echo $result2 > result.txt
array=($(awk -F '[:,"}]' '{$1="";print $0}' result.txt))
echo ${array[@]}
rm -rf result.txt

#test AddNode_2
contains $attester_2 $res_score2
contains $attestee_2 $res_score1


# stop iota and cli
ps -aux | grep "[g]o-build" | awk '{print $2}' | xargs kill -9
ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9

sleep 1
# return iri dir
cd ../../../../
rm -rf iri/node1/iri1.log
echo "run over"


