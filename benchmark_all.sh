#!/bin/bash
set -e

PASSWORD="pass"
REQUESTS=100000
CONCURRENCY=50
DATA_SIZE=256

echo "=========================================="
echo "Valkey Cluster Benchmark"
echo "Requests: ${REQUESTS}"
echo "Concurrency: ${CONCURRENCY}"
echo "Data Size: ${DATA_SIZE} bytes"
echo "=========================================="
echo ""

NETWORK="keydb_valkey_valkey_cluster"

# Бенчмарк кластера — все primary-ноды одновременно (-C = cluster mode)
echo "========== Cluster (3 primary nodes) =========="
echo "------------------------------------------"

docker run --rm --network "$NETWORK" \
    valkey/valkey:9 \
    valkey-benchmark \
    -C valkey_node1:6379 valkey_node2:6379 valkey_node3:6379 \
    -a "$PASSWORD" \
    -t set \
    -n "$REQUESTS" \
    -c "$CONCURRENCY" \
    -d "$DATA_SIZE" \

echo ""
echo "=========================================="
echo "All benchmarks completed!"
echo "=========================================="
