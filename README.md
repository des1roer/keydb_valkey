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
    valkey/valkey:8 \
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