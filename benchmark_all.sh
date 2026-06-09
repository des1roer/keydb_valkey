#!/bin/bash
set -e

PASSWORD="pass"
REQUESTS=100000
CONCURRENCY=50
DATA_SIZE=256

echo "=========================================="
echo "Unified Benchmark Suite (valkey-benchmark)"
echo "Requests: ${REQUESTS}"
echo "Concurrency: ${CONCURRENCY}"
echo "Data Size: ${DATA_SIZE} bytes"
echo "=========================================="
echo ""

# Функция для запуска бенчмарка
run_benchmark() {
    local name=$1
    local host=$2

    echo "📊 Testing: ${name} (${host})"
    echo "------------------------------------------"

    docker run --rm --network $(docker network ls -q -f name=db_ha) \
        valkey/valkey:8 \
        valkey-benchmark \
        -h ${host} \
        -p 6379 \
        -a ${PASSWORD} \
        -t set \
        -n ${REQUESTS} \
        -c ${CONCURRENCY} \
        -d ${DATA_SIZE} \

    echo ""
}

# Тест всех систем
echo "========== SET Operations =========="
run_benchmark "KeyDB (Active-Active)" "haproxy"
run_benchmark "Valkey (Master-Replica)" "haproxy_valkey"
run_benchmark "Redis (Master-Replica)" "haproxy_redis"

echo "=========================================="
echo "✅ All benchmarks completed!"
echo "=========================================="
