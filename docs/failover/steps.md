# Начальное состояние

```bash
make val-repl-info
>
=== valkey_primary INFO replication ===
role:master
connected_slaves:1

=== valkey_replica INFO replication ===
role:slave
master_host:valkey_primary
master_port:6379

=== Sentinel get-master-addr-by-name ===
172.21.0.2
6379
```

# Switch

```bash
make val-failover
>
=== valkey_primary INFO replication ===
role:master
connected_slaves:1

=== valkey_replica INFO replication ===
role:slave
master_host:172.21.0.2
master_port:6379

=== Sentinel get-master-addr-by-name ===
172.21.0.2
6379

=== Останавливаем valkey_primary ===
valkey_primary
  valkey_primary остановлен

  Ждём Sentinel (15s)...

=== Состояние ПОСЛЕ failover ===

=== valkey_replica INFO replication ===
role:master
connected_slaves:0

=== Sentinel get-master-addr-by-name ===
172.21.0.3
6379

✅ Failover завершён. Проверьте что replica стала role:master
```