#!/usr/bin/env bash
echo "running test 12 testnet - genensis forward"

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
                        --ancestor-forward-enable true --ancestor-create-frequency 1000 \
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

# start nginx
sed -i -e "s/LOCAL_IP/localhost/g" iri/scripts/iota_perf/nginx.conf
sudo cp iri/scripts/iota_perf/nginx.conf /etc/nginx/
sudo nginx -s reload

# start jmeter
cd iri/scripts/iota_perf
bash -x ./run_perf.sh

# stop iota and cli
ps -aux | grep "[p]ython app.py" | awk '{print $2}' | xargs kill -9
ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9
mv iri/scripts/iota_api/conf.bak iri/scripts/iota_api/conf

# check
diff order1 order2
if [ $? != 0 ]; then
    echo "Failed! order is not equal!"
    echo "cat order1"
    cat order1
    echo
    echo "cat order2"
    cat order2
    exit -1
else
    echo "Genesis forward is OK!"
fi

cd ${DIR}
