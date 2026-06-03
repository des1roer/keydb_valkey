# CLAUDE.md — keydb_valkey

## О проекте

Лаборатория для **сравнительного бенчмарка KeyDB, Valkey и Redis** с высокой доступностью.
Три базы работают одновременно на одной Docker-сети, каждая со своим HAProxy.
Есть единый миграционный прокси (`haproxy_migrate`) для бесшовного переключения KeyDB ↔ Valkey.

## Архитектура

```
Клиент → haproxy_migrate :6690
              │
              ├─ keydb_node1 :6379  (Multi-Master, active-active)
              ├─ keydb_node2 :6379  (Multi-Master, active-active)
              │
              ├─ valkey_primary :6379  (Active-Passive + Sentinel)
              │  └─ valkey_replica (backup)
              │
              └─ redis_primary :6379   (Active-Passive + Sentinel)
                 └─ redis_replica (backup)
```

Каждая база также имеет свой собственный HAProxy с отдельным портом:

| Сервис                      | Порт | Архитектура                          |
|-----------------------------|------|--------------------------------------|
| KeyDB (haproxy)             | 6677 | Multi-Master (active-active)         |
| Valkey (haproxy_valkey)     | 6680 | Primary-Replica + Sentinel           |
| Redis (haproxy_redis)       | 6684 | Primary-Replica + Sentinel           |
| Migration (haproxy_migrate) | 6690 | Единый вход, hot-switch KeyDB↔Valkey |

## Как работать

### Запуск / остановка
```bash
make up          # запустить всё
make down        # остановить + убрать orphans
make ps          # показать статус
```

### Бенчмарк
```bash
bash benchmark_all.sh
```
Запускает `valkey-benchmark` через каждый HAProxy: 100K запросов, 50 клиентов, 256B payload, операция SET.

### Подключение к контейнерам
```bash
make kdb1          # shell в keydb_node1
make kdb2          # shell в keydb_node2
make val-primary   # shell в valkey_primary
make val-replica   # shell в valkey_replica
make redis-primary # shell в redis_primary
```

### Миграция KeyDB → Valkey
```bash
# 1. Синхронизировать данные
docker exec keydb_node1 keydb-cli -a pass BGSAVE
docker cp keydb_node1:/data/dump.rdb ./dump.rdb
docker cp ./dump.rdb valkey_primary:/data/dump.rdb
docker exec valkey_primary valkey-cli -a pass DEBUG LOAD

# 2. Проверить, что DBSIZE совпал
docker exec keydb_node1 keydb-cli -a pass DBSIZE
docker exec valkey_primary valkey-cli -a pass DBSIZE

# 3. Переключить трафик (без изменения кода приложения)
make migrate-to-valkey

# 4. Вернуть обратно
make migrate-to-keydb
```

## Ключевые файлы

| Файл                  | Назначение                                                   |
|-----------------------|--------------------------------------------------------------|
| `docker-compose.yaml` | Оркестрация всех сервисов                                    |
| `.env`                | Все переменные (порты, пароли). `.env.local` НЕ используется |
| `haproxy.cfg`         | KeyDB load balancer (round-robin, оба active)                |
| `haproxy_valkey.cfg`  | Valkey load balancer (primary active, replica backup)        |
| `haproxy_redis.cfg`   | Redis load balancer (primary active, replica backup)         |
| `haproxy_migrate.cfg` | Единый прокси с runtime API для hot-switch                   |
| `benchmark_all.sh`    | Скрипт бенчмарка                                             |
| `Makefile`            | Удобные команды для управления                               |

## Важные конвенции

- **Все пароли** — `pass` (из `.env`)
- **Порт внутри контейнера** — всегда 6379
- **Ресурсы** — 1 CPU / 1GB для данных, 0.5 CPU / 256MB для proxy/sentinel
- **Network** — все контейнеры на `db_ha` (bridge)
- **Комментарии** — на русском языке
- **Sentinel** — генерируется динамически (не из файлов в `conf/`)
- KeyDB и Valkey **нельзя реплицировать друг к другу** (разные реализации протокола репликации)

## WSL-специфика

- Docker вызывается из WSL Ubuntu
- Конфиги сентинелей в `conf/` принадлежат root — не перезаписывать через Windows
- Права на `conf/` сломаны — использовать `wsl -d Ubuntu sudo` или избегать этой директории
- Данные монтируются через bind mounts, сохраняются между перезапусками
