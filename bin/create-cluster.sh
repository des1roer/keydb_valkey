#!/bin/bash
set -e

PASSWORD="${VALKEY_PASSWORD:-pass}"

echo "=== Ожидание запуска всех нод ==="
for i in $(seq 1 6); do
    echo -n "  valkey_node$i ... "
    until docker exec valkey_node$i valkey-cli -a $PASSWORD PING 2>/dev/null | grep -q PONG; do
        sleep 1
    done
    echo "OK"
done

echo ""
echo "=== Создание кластера (3 primary + 3 replica) ==="
docker run --rm --network keydb_valkey_db_ha \
    -e VALKEY_PASSWORD=$PASSWORD \
    valkey/valkey:9 \
    valkey-cli --cluster create \
        valkey_node1:6379 valkey_node2:6379 valkey_node3:6379 \
        valkey_node4:6379 valkey_node5:6379 valkey_node6:6379 \
        --cluster-replicas 1 \
        -a $PASSWORD --cluster-yes

echo ""
echo "=== Проверка кластера ==="
docker exec valkey_node1 valkey-cli -a $PASSWORD -c CLUSTER INFO 2>/dev/null | grep -v Warning
echo ""
docker exec valkey_node1 valkey-cli -a $PASSWORD -c CLUSTER NODES 2>/dev/null | grep -v Warning
