# keydb_valkey

```bash
docker run --rm --network $(docker network ls -q -f name=db_ha) \
    eqalpha/keydb:x86_64_v6.3.4 \
    keydb-benchmark -h haproxy -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 5133.47 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.790     0.120     1.375    77.759    80.063    86.463

```

```bash
docker run --rm --network $(docker network ls -q -f name=db_ha) \
    valkey/valkey:9 \
    valkey-benchmark -h keydb_node1 -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 36010.08 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        1.153     0.296     0.839     1.535    17.599    26.303

```

```bash
docker run --rm --network $(docker network ls -q -f name=db_ha) \
    valkey/valkey:9 \
    valkey-benchmark -h haproxy_valkey -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 5440.99 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.480     0.112     1.639    76.031    78.911    85.055
```

```bash 
docker run --rm --network $(docker network ls -q -f name=db_ha) \
    valkey/valkey:9 \
    valkey-benchmark -h valkey_primary -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 45516.61 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        0.732     0.176     0.647     1.087     1.567    12.135
```

```bash 
docker run --rm --network $(docker network ls -q -f name=valkey_cluster) \
    valkey/valkey:9 \
    valkey-benchmark -h valkey_node1 -p 6379 -a pass -t set -n 100000 -c 50 -d 256 --cluster
```

```
Summary:
  throughput summary: 99800.40 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        0.422     0.104     0.407     0.631     0.799    14.111
```

```bash
docker run --rm --network $(docker network ls -q -f name=db_ha) \
    redis:7.4-alpine \
    redis-benchmark -h haproxy_redis -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 5534.34 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.265     0.088     1.583    75.455    77.887    84.095
```

```bash
docker run --rm --network $(docker network ls -q -f name=db_ha) \
    valkey/valkey:9 \
    valkey-benchmark -h redis_primary -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 45085.66 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        0.622     0.144     0.543     1.071     1.359     5.015
```

```bash
chmod +x benchmark_all.sh
./benchmark_all.sh
```

```
📊 Testing: KeyDB (Active-Active) (haproxy)
------------------------------------------
====== SET ======                                                  
  100000 requests completed in 19.63 seconds
  50 parallel clients
  256 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": no
  multi-thread: no


Summary:
  throughput summary: 5095.28 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.871     0.120     1.391    78.079    80.255    89.215


📊 Testing: Valkey (Master-Replica) (haproxy_valkey)
------------------------------------------
====== SET ======                                                  
  100000 requests completed in 18.01 seconds
  50 parallel clients
  256 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": no
  multi-thread: no

Summary:
  throughput summary: 5551.24 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.278     0.128     1.583    75.967    78.335    84.351


📊 Testing: Redis (Master-Replica) (haproxy_redis)
------------------------------------------
====== SET ======                                                  
  100000 requests completed in 18.17 seconds
  50 parallel clients
  256 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": no
  
Summary:
  throughput summary: 5502.67 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.389     0.112     1.583    76.479    78.719   192.639
```

make migrate-data

```
=== 1. KeyDB: DBSIZE до миграции ===
4

=== 2. KeyDB: BGSAVE (сохраняем дамп) ===
Background saving started
  Ждём завершения dump...

=== 3. Копируем dump.rdb на хост ===
Successfully copied 2.56kB to /home/des/proj/keydb_valkey/dump.rdb
  dump.rdb скопирован, размер: 668

=== 4. Останавливаем valkey_primary ===
valkey_primary
  valkey_primary остановлен

=== 5. Копируем dump.rdb в valkey_primary ===
Successfully copied 2.56kB to valkey_primary:/data/dump.rdb
  dump.rdb размещён в контейнере

=== 6. Запускаем valkey_primary (автозагрузка dump.rdb) ===
valkey_primary
  valkey_primary запущен
  Ждём загрузки данных...

=== 7. Проверка результата ===
  KeyDB  DBSIZE: 4
  Valkey DBSIZE: 4

=== 8. Очистка ===
  ./dump.rdb удалён

✅ Миграция завершена. Дальше:
   make migrate-to-valkey   # переключить трафик на Valkey
   make migrate-to-keydb    # вернуть обратно на KeyDB
```
