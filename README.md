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
    valkey-benchmark -h haproxy_valkey -p 6379 -a pass -t set -n 100000 -c 50 -d 256
```

```
Summary:
  throughput summary: 5597.85 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        8.239     0.112     1.599    76.095    78.335    84.543
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
