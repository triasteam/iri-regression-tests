import sys
from common import get_transactions_count, start_cli, put_cache, put_file, check_transactions_count, stop_cli

TX_NUM = 100
total_tx_num = 0

# 0. parse arguments
if sys.argv[2] == "true":
    enable_ipfs = True
else:
    enable_ipfs = False

if sys.argv[3] == "true":
    enable_batch = True
else:
    enable_batch = False

if sys.argv[4] == "true":
    enable_compression = True
else:
    enable_compression = False

# 1. cli
print("\nstart cli: enable_ipfs %d, enable_batch %d, enable_compression %d" % (enable_ipfs, enable_batch, enable_compression))
start_cli(enable_ipfs, enable_batch, enable_compression)

# 2. tx count
tx_count = get_transactions_count()
print("current tx count is %d" % int(tx_count))

# 3. put_cache
if enable_batch:
    print("\nstart put_cache...")
    put_cache(TX_NUM)
    total_tx_num += TX_NUM

# 4. put_file
print("\nstart put_file...")
put_file(TX_NUM)
total_tx_num += TX_NUM

# 5. check tx count
print("\n\nchecking transaction count...")
check_transactions_count(tx_count, total_tx_num)

# 6. stop cli
print("\nstopping cli...")
stop_cli()
