import os
import time
import commands
import subprocess
import signal
import sh

# start iota
def start_iota(node=1):
    jar_file = "node%d/iri-1.5.5.jar" % (node)
    log_file = "node%d/iri.log" % (node)
    _status = sh.java("-jar", jar_file, "-p", "14700", "-u", "14700", "-t", "14701",
                     "-n", "udp://localhost:14699", "udp://localhost:14701", "--testnet", "--testnet-no-coo-validation",
                     "--snapshot=./Snapshot.txt", "--mwm", "1", "--walk-validator", "NULL", "--ledger-validator", "NULL",
                     "--max-peers", "40", "--remote", "--ipfs-txns", "false", "--batch-txns", _out=log_file, _bg=True)

    time.sleep(8)


# stop iota
def stop_iota(node=1):
    p = subprocess.Popen(['ps', '-aux'], stdout=subprocess.PIPE)
    out, err = p.communicate()
    for line in out.splitlines():
        if ('java -jar node%d/iri' % node) in line:
            pid = int(line.split()[1])
            os.kill(pid, signal.SIGKILL)


def start_cli(enable_ipfs=True, enable_batch=False, enable_compression=False, node=1):
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
    log_file = "%s/node%d/app.log" % (cur_dir, node)
    sh.python("./app.py", _out=log_file, _bg=True)
    os.chdir(cur_dir)

    time.sleep(3)


def stop_cli():
    p = subprocess.Popen(['ps', '-aux'], stdout=subprocess.PIPE)
    out, err = p.communicate()
    for line in out.splitlines():
        if ('app.py') in line:
            pid = int(line.split()[1])
            os.kill(pid, signal.SIGKILL)

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
def get_transactions_count(node=1):
    log_file = "node%d/iri.log" % node
    tx_count = sh.awk(sh.tail(sh.grep("-a", "totalTransactions =", log_file), "-n", "1"), '{print $25}')
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
