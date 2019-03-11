import common, time, os

print("running test failover_test_txn_count")

os.chdir('iri')

print("\nStarting cli...\n")
common.start_cli(False, True, False)

print("\nStarting iota...\n")
common.start_iota()

print("\nSending milestone...\n")
common.send_milestone()

print("\nStarting to send txs...\n")
common.put_file(20)
time.sleep(20)


txn_count = common.get_transactions_count()
print("\nold tx_count = %s\n" % txn_count)

print("\nStopping iota...\n")
common.stop_iota()
time.sleep(5)

print("\nRestarting iota...\n")
common.start_iota()
time.sleep(20)

new_txn_count = common.get_transactions_count()
print("\nnew tx_count = %s\n" % new_txn_count)

print("\nStopping iota and cli...\n")
common.stop_iota()
common.stop_cli()

if txn_count == new_txn_count:
    print('\nYes, restarted successfully!')
else:
    print("\nError, %s != %s" % (txn_count, new_txn_count))
    exit(-1)