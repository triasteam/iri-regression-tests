#!/usr/bin/env bash

# clean tx data
rm -rf testnetdb*
rm -rf ixi
rm -rf streamnet*

java -jar iri/target/iri-1.5.5.jar --testnet \
                        --mwm 1 \
                        --walk-validator "NULL" \
                        --ledger-validator "NULL" \
                        -p 14700 \
                        --max-peers 40 \
                        --remote \
                        --enable-streaming-graph \
                        --entrypoint-selector-algorithm "KATZ" \
                        --tip-sel-algo "CONFLUX" \
                        --ipfs-txns false \
                        --batch-txns false \
                        --weight-calculation-algorithm "IN_MEM" \
                        &>  streamnet-tee.log &

# startup python client
cd iri/scripts/scripts/front_end/server
go run main.go -host http://127.0.0.1:14700 &> iri/app-tee.log  &

sleep 10

# create tee with no privilege
curl -s -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"192.168.130.2\",\"Attestee\":\"192.168.130.3\",\"Score\":\"1\"}"
# create tee with privilege
curl -s -X POST http://127.0.0.1:8000/AddNode -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"Attester\":\"192.168.130.4\",\"Attestee\":\"192.168.130.5\",\"Score\":\"1\",\"Address\":\"123456\",\"private_key\":\"123\",\"Sign\":\"EoZ1BUTxD088WiZJCHRibpv3SKj5gcpnAT15ffEXHWGZ6ExxSRm8/7gHmelpIVG0+qGSgOJ9vhF/sU3FzkvYz8Q9G49N9B69YzGWPmg/6R36yeMV/o6D50imqcbPLCbeORkeS5hoOQVVfP1l0y5KutOnkFB0fLf3lihpzZeYvfs=\"}"
# query result
curl -s -X POST http://127.0.0.1:8000/QueryNodes -H 'Content-Type:application/json' -H 'cache-control: no-cache' -d "{\"period\":1,\"numRank\":100}" | jq ''
