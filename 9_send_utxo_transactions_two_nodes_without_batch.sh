#!/bin/bash
echo "running test 9 testnet - Send transactions -- two nodes, without batch"

set -e

PORT1=14700
PORT2=13700

DIR=$PWD

# clear
rm -rf db*

mkdir -p iri/node1 iri/node2

# start iota
java -jar iri/target/iri-1.5.5.jar --testnet --mwm 1 --walk-validator "NULL" --ledger-validator "NULL" -p ${PORT1} \
                        --udp-receiver-port $((PORT1-100)) --tcp-receiver-port $((PORT1-100)) --db-path "./db1" \
                        --db-log-path "./db1.log" --neighbors "tcp://localhost:$((PORT2-100))" --max-peers 40 --remote \
                        --enable-streaming-graph --entrypoint-selector-algorithm "KATZ" --tip-sel-algo "CONFLUX" \
                        --ipfs-txns false --batch-txns --weight-calculation-algorithm "IN_MEM" \
                        &>  iri/node1/iri.log &

sleep 1

java -jar iri/target/iri-1.5.5.jar --testnet --mwm 1 --walk-validator "NULL" --ledger-validator "NULL" -p ${PORT2} \
                        --udp-receiver-port $((PORT2-100)) --tcp-receiver-port $((PORT2-100)) --db-path "./db2" \
                        --db-log-path "./db2.log" --neighbors "tcp://localhost:$((PORT1-100))" --max-peers 40 --remote \
                        --enable-streaming-graph --entrypoint-selector-algorithm "KATZ" --tip-sel-algo "CONFLUX" \
                        --ipfs-txns false --batch-txns --weight-calculation-algorithm "IN_MEM" \
                        &>  iri/node2/iri.log &

sleep 1

# start cli
cd iri/scripts/iota_api
cp conf conf.bak
cp ../examples/two_nodes/cli_conf_two_nodes_1 conf
python app.py &> ${DIR}/iri/node1/app.log  &

sleep 10

cp ../examples/two_nodes/cli_conf_two_nodes_2 conf
python app.py &> ${DIR}/iri/node2/app.log  &

cd ${DIR}

sleep 5

# send transactions parallelly
bash iri/scripts/examples/two_nodes/parallel_put_txn_double_spend.sh

sleep 40

# get the total balance
total_1=0
total_2=0
declare -A balances_1
declare -A balances_2
FLAG="false"
for account in {a..z} {A..Z}
do
    balances_1[$account]=$(curl -s -X GET http://127.0.0.1:5000/get_balance -H 'Content-Type: application/json' -H 'cache-control: no-cache' -d "{\"account\": \"$account\"}")
    balances_2[$account]=$(curl -s -X GET http://127.0.0.1:6000/get_balance -H 'Content-Type: application/json' -H 'cache-control: no-cache' -d "{\"account\": \"$account\"}")
    total_1=$((total_1+balances_1[$account]))
    total_2=$((total_2+balances_2[$account]))
    if [ ${balances_1[$account]} != ${balances_2[$account]} ] ; then
        echo "Balances of" $account "in node1 and node2 are different:" ${balances_1[$account]} -- ${balances_2[$account]}
        FLAG="true"
        #break
    fi
    echo "total balances " $total_1 -- $total_2
done

# check the total balance
if [ ${FLAG} == "false" ] && [ ${total_1} -eq "1000000000" ] && [ ${total_2} -eq "1000000000" ];
then
    echo
    echo "UTXO with double spending is OK!"

    # stop iota and cli
    ps -aux | grep "[p]ython app.py" | awk '{print $2}' | xargs kill -9
    ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9
    mv iri/scripts/iota_api/conf.bak iri/scripts/iota_api/conf
else
    echo "Wrong!"
    echo "    FLAG = " $FLAG
    echo "    total of node1" ${total_1}
    echo "    total of node2" ${total_2}
    curl -s http://localhost:5000/get_utxo -X GET -H "Content-Type: application/json" -d "{\"type\":\"DOT\"}"
    curl -s http://localhost:6000/get_utxo -X GET -H "Content-Type: application/json" -d "{\"type\":\"DOT\"}"
    curl -s http://localhost:5000/get_dag -X GET -H "Content-Type: application/json" -d "{\"type\":\"DOT\"}"
    curl -s http://localhost:6000/get_dag -X GET -H "Content-Type: application/json" -d "{\"type\":\"DOT\"}"
    curl -s http://localhost:5000/get_total_order -X GET -H "Content-Type: application/json"
    curl -s http://localhost:6000/get_total_order -X GET -H "Content-Type: application/json"

    # stop iota and cli
    ps -aux | grep "[p]ython app.py" | awk '{print $2}' | xargs kill -9
    ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9
    mv iri/scripts/iota_api/conf.bak iri/scripts/iota_api/conf

    exit -1
fi