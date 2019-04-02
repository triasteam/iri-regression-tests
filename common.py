import os
import time
import commands
import subprocess
import signal
import sh

# start iota
def start_iota():
    status = os.system('java -jar node1/iri-1.5.5.jar -p 14700 -u 14700 -t 14701 -n udp://localhost:14699 udp://localhost:14701 --testnet --testnet-no-coo-validation --snapshot=./Snapshot.txt --mwm 1 --walk-validator "NULL" --ledger-validator "NULL" --max-peers 40 --remote --ipfs-txns false --batch-txns > node1/iri.log 2>&1 &')
    #print status, output
    if status != 0:
        print "Start IOTA failed: "
        exit(-1)

    time.sleep(8)


# stop iota
def stop_iota():
    p = subprocess.Popen(['ps', '-aux'], stdout=subprocess.PIPE)
    out, err = p.communicate()
    for line in out.splitlines():
        if 'java -jar node1/iri' in line:
            pid = int(line.split()[1])
            os.kill(pid, signal.SIGKILL)


def start_cli(enable_ipfs=True, enable_batch=False, enable_compression=False):
    # change config
    cur_dir = os.getcwd()

    conf_file= "scripts/iota_api/conf"
    sh.cp(conf_file, conf_file + ".bak")
    file_data = ""
    with open(conf_file, "r") as f:
        for line in f:
            if "enableIpfs" in line:
                if enable_ipfs == True:
                    file_data += "enableIpfs = True\n"
                else:
                    file_data += "enableIpfs = False\n"
            elif "enableBatching" in line:
                if enable_batch == True:
                    file_data += "enableBatching = True\n"
                else:
                    file_data += "enableBatching = False\n"
            elif "enableCompression" in line:
                if enable_compression == True:
                    file_data += "enableCompression = True\n"
                else:
                    file_data += "enableCompression = False\n"
            else:
                file_data += line

    with open(conf_file, "w") as f:
        f.write(file_data)

    os.chdir("scripts/iota_api")
    os.system("python ./app.py > /tmp/app.log 2>&1 &")
    os.chdir(cur_dir)

    time.sleep(3)


def stop_cli():
    os.system('ps -aux | grep "[p]ython ./app" | awk \'{print $2}\' | xargs kill -9')
    sh.mv("scripts/iota_api/conf.bak", "scripts/iota_api/conf")


# send transactions one by one
def put_file(txn_num=1):
    for i in range(txn_num):
        ret = os.system('curl -s -X POST http://127.0.0.1:5000/put_file -H \'Content-Type: application/json\' -H \'cache-control: no-cache\' -d \'{"from": "A","to": "j","amnt": 1, "tag": "TX"}\'')
        if ret != 0:
            print "Send command failed ", i
            exit(-1)


# send transactions in batches
def put_cache(txn_num=1):
    for i in range(txn_num):
        ret = os.system('curl -s -X POST   http://127.0.0.1:5000/put_cache -H \'Content-Type: application/json\' -H \'cache-control: no-cache\' -d \'{"from": "A","to": "j","amnt": 1, "tag": "TX"}\'')
        if ret != 0:
            print "Send command failed ", i
            exit(-1)


# get current txn count
def get_transactions_count():
    tx_count = commands.getoutput("grep -a \"totalTransactions =\" ./node1/iri.log  | tail -n 1 | awk '{print $25}'")
    return tx_count


def check_transactions_count(old_tx_count, COUNT):
    new_tx_count = ""
    for i in range(40):
        new_tx_count = get_transactions_count()
        if int(new_tx_count) == int(old_tx_count) + COUNT:
            print "IOTA transaction count added successfully"
            return
        else:
            time.sleep(1)

    print "Error! transaction number added failed:", old_tx_count, "+", COUNT, "!=", new_tx_count
    exit(-1)
