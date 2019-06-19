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
                        --ipfs-txns false --batch-txns true --weight-calculation-algorithm "IN_MEM" \
                        &>  iri/node1/iri.log &

sleep 1

java -jar iri/target/iri-1.5.5.jar --testnet --mwm 1 --walk-validator "NULL" --ledger-validator "NULL" -p ${PORT2} \
                        --udp-receiver-port $((PORT2-100)) --tcp-receiver-port $((PORT2-100)) --db-path "./db2" \
                        --db-log-path "./db2.log" --neighbors "tcp://localhost:$((PORT1-100))" --max-peers 40 --remote \
                        --enable-streaming-graph --entrypoint-selector-algorithm "KATZ" --tip-sel-algo "CONFLUX" \
                        --ipfs-txns false --batch-txns true --weight-calculation-algorithm "IN_MEM" \
                        &>  iri/node2/iri.log &

sleep 1

# start cli
cd iri/scripts/iota_api
cp conf conf.bak
cp ../examples/two_nodes_batch/cli_conf_two_nodes_1 conf
python app.py &> ${DIR}/iri/node1/app.log  &

sleep 10

cp ../examples/two_nodes_batch/cli_conf_two_nodes_2 conf
python app.py &> ${DIR}/iri/node2/app.log  &

cd ${DIR}


# start nginx
sed -i -e "s/LOCAL_IP/localhost/g" iri/scripts/iota_perf/nginx.conf
sudo cp iri/scripts/iota_perf/nginx.conf /etc/nginx/
sudo nginx -s reload

sleep 60 

# start jmeter

# It will check the result in 'run_perf.sh'

cd iri/scripts/iota_perf
python data_generate.py 10000

# run ramp up
sed -e 's/NUM_CALL/500/g'       \
    -e 's/NUM_THREAD/1/g'       \
    -e 's/PORT/5000/g'          \
    -e 's/DATA/data/g'          \
    -e 's/ACTION/put_file/g'   PerformanceTestDAG2TM_TPS.jmx > PerformanceTest.jmx
jmeter -n -t PerformanceTest.jmx

sleep 10

# run perf with multi-threading
sed -e 's/NUM_CALL/5000/g'  \
    -e 's/NUM_THREAD/2/g'   \
    -e 's/PORT/8080/g'      \
    -e 's/DATA/data1/g'     \
    -e 's/ACTION/put_cache/g' PerformanceTestDAG2TM_TPS.jmx > PerformanceTest1.jmx
jmeter -n -t PerformanceTest1.jmx

sleep 30

# check balance
./check_result.sh

# check order
curl -s -X GET http://127.0.0.1:5000/get_total_order -H 'Content-Type: application/json' -H 'cache-control: no-cache' > order1
curl -s -X GET http://127.0.0.1:6000/get_total_order -H 'Content-Type: application/json' -H 'cache-control: no-cache' > order2
diff order1 order2

cd ${DIR}

# stop iota and cli
ps -aux | grep "[p]ython app.py" | awk '{print $2}' | xargs kill -9
ps -aux | grep "[j]ava -jar iri" | awk '{print $2}' | xargs kill -9
mv iri/scripts/iota_api/conf.bak iri/scripts/iota_api/conf

