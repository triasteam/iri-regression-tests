import api
import time
import sys
import commands
import os

# 1. get current txn count
tx_count = commands.getoutput("grep \"totalTransactions =\" iota.log  | tail -n 1 | awk '{print $25}'")

# 2. send batch of transactions
ret = os.system('curl -X POST   http://127.0.0.1:5000/put_file   -H \'Content-Type: application/json\'   -H \'cache-control: no-cache\' -d \'{"type": "trans","from_address": "i","to_address": "j","amount": "6"}\'')
if ret == 0:
    print "Send command successfully."
else:
    print "Send command failed."
    exit(-1)

# 3. after some seconds, get current txn count and judge
counter = 0
while 1:
    time.sleep(3)
    new_tx_count = commands.getoutput("grep \"totalTransactions =\" iota.log  | tail -n 1 | awk '{print $25}'")
    if new_tx_count == tx_count + 1:
        print "IOTA transaction count added successfully"
        exit(0)
    else:
        counter += 1
        if counter < 30:
            print "waiting for IOTA transaction count..."
        else:
            print "Error! transaction number added failed!"
            exit(-1)

