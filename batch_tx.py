import time
import commands
import os

txn_num = 1

# 0. send milestone
ret = os.system("java -jar ../../private-iota-testnet/target/iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar Coordinator localhost 14700")
if ret == 0:
    print "Send milestone successfully"
else:
    print "Send milestone failed"
    exit(-1)

# 1. get current txn count
tx_count = commands.getoutput("grep \"totalTransactions =\" ./node1/iri.log  | tail -n 1 | awk '{print $25}'")
print "tx_count = ", tx_count

# 2. send batch of transactions
for i in range(txn_num):
    ret = os.system('curl -X POST   http://127.0.0.1:5000/put_file   -H \'Content-Type: application/json\'   -H \'cache-control: no-cache\' -d \'{"type": "trans","from_address": "i","to_address": "j","amount": "6"}\'')
    if ret == 0:
        print "Send command successfully ", i
    else:
        print "Send command failed ", i
        exit(-1)

# 3. after some seconds, get current txn count and judge
counter = 0
while 1:
    time.sleep(3)
    new_tx_count = commands.getoutput("grep \"totalTransactions =\" ./node1/iri.log  | tail -n 1 | awk '{print $25}'")
    print "new_tx_count = ", new_tx_count
    if int(new_tx_count) == int(tx_count) + txn_num:
        print "IOTA transaction count added successfully"
        exit(0)
    else:
        counter += 1
        if counter < 30:
            print "waiting for IOTA transaction count..."
        else:
            print "Error! transaction number added failed!"
            exit(-1)

