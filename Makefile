DOCKER_COMP = docker-compose -f docker-compose-all.yaml

default: up

up:
	@$(DOCKER_COMP) up -d

d: down

down:
	docker compose down --remove-orphans

build:
	@$(DOCKER_COMP) build

ps:
	@$(DOCKER_COMP) ps

# ── KEYDB ──
kdb1:
	@$(DOCKER_COMP) exec keydb_node1 bash
kdb2:
	@$(DOCKER_COMP) exec keydb_node2 bash

# ── VALKEY MASTER-REPLICA + SENTINEL (docker-compose-valkey.yaml) ──
VAL_COMP = docker compose -f docker-compose-valkey.yaml

val-up:
	@$(VAL_COMP) up -d

val-down:
	@$(VAL_COMP) down --remove-orphans

val-ps:
	@$(VAL_COMP) ps

val-primary:
	@$(VAL_COMP) exec valkey_primary bash

val-replica:
	@$(VAL_COMP) exec valkey_replica bash

val-sentinel:
	@$(VAL_COMP) exec valkey_sentinel bash

# Информация о репликации (до failover)
val-repl-info:
	@echo "=== valkey_primary INFO replication ==="
	@docker exec valkey_primary valkey-cli -a pass INFO replication 2>/dev/null | grep -E 'role|connected_slaves' || true
	@echo ""
	@echo "=== valkey_replica INFO replication ==="
	@docker exec valkey_replica valkey-cli -a pass INFO replication 2>/dev/null | grep -E 'role|master_host|master_port' || true
	@echo ""
	@echo "=== Sentinel get-master-addr-by-name ==="
	@docker exec valkey_sentinel valkey-cli -p 26379 SENTINEL get-master-addr-by-name valkey_cluster 2>/dev/null || true

# Тест failover: остановить primary, Sentinel должен повысить replica
val-failover: val-repl-info
	@echo ""
	@echo "=== Останавливаем valkey_primary ==="
	@docker stop valkey_primary
	@echo "  valkey_primary остановлен"
	@echo ""
	@echo "  Ждём Sentinel (5s)..."
	@sleep 5
	@echo ""
	@echo "=== Состояние ПОСЛЕ failover ==="
	@echo ""
	@echo "=== valkey_replica INFO replication ==="
	@docker exec valkey_replica valkey-cli -a pass INFO replication 2>/dev/null | grep -E 'role|connected_slaves' || true
	@echo ""
	@echo "=== Sentinel get-master-addr-by-name ==="
	@docker exec valkey_sentinel valkey-cli -p 26379 SENTINEL get-master-addr-by-name valkey_cluster 2>/dev/null || true
	@echo ""
	@echo "✅ Failover завершён. Проверьте что replica стала role:master"

# Перезапустить primary как реплику после failover
val-rejoin-primary:
	@echo "=== Запускаем valkey_primary (как replica нового мастера) ==="
	@$(VAL_COMP) up -d valkey_primary
	@sleep 3
	@echo "=== valkey_primary INFO replication ==="
	@docker exec valkey_primary valkey-cli -a pass INFO replication 2>/dev/null | grep -E 'role|master_host|master_port' || true

# ── PHP TEST ──
php-test:
	@$(DOCKER_COMP) exec php-test php /app/test-cluster.php

# ── REDIS ──
redis-primary:
	@$(DOCKER_COMP) exec redis_primary bash
redis-replica:
	@$(DOCKER_COMP) exec redis_replica bash
redis-sentinel:
	@$(DOCKER_COMP) exec redis_sentinel bash

# ── MIGRATION PROXY ──
migrate-status:
	@echo "=== Current backend routing ==="
	@echo "show stat" | nc -q1 -w1 localhost 9999 2>/dev/null || \
		docker exec haproxy_migrate sh -c 'echo "show stat" | socat - /var/run/haproxy.sock' || \
		echo "haproxy_migrate not running. Start with: make up"

# Switch to KeyDB (default)
migrate-to-keydb:
	@echo "Switching to KeyDB backend..."
	@docker exec haproxy_migrate sh -c 'echo "set default-server valkey_backend state maint" | socat - /var/run/haproxy.sock' 2>/dev/null || true
	@docker exec haproxy_migrate sh -c 'echo "set server keydb_backend/node1 state ready" | socat - /var/run/haproxy.sock' 2>/dev/null || true
	@docker exec haproxy_migrate sh -c 'echo "set server keydb_backend/node2 state ready" | socat - /var/run/haproxy.sock' 2>/dev/null || true
	@echo "Routing: KeyDB Multi-Master"

# Switch to Valkey
migrate-to-valkey:
	@echo "Switching to Valkey backend..."
	@docker exec haproxy_migrate sh -c 'echo "set default-server keydb_backend state maint" | socat - /var/run/haproxy.sock' 2>/dev/null || true
	@docker exec haproxy_migrate sh -c 'echo "set server valkey_backend/primary state ready" | socat - /var/run/haproxy.sock' 2>/dev/null || true
	@echo "Routing: Valkey (primary→replica)"

# ── DATA MIGRATION: KeyDB → Valkey Cluster (via RedisShake) ──
# RedisShake: sync_reader (RDB) → redis_writer (cluster)
# Конфиг: bin/redis-shake.toml
migrate-cluster:
	@echo "=== 1. KeyDB: DBSIZE до миграции ==="
	@docker exec keydb_node1 keydb-cli -a pass DBSIZE 2>&1 | grep -v Warning
	@echo ""
	@echo "=== 2. RedisShake: миграция KeyDB → Valkey Cluster ==="
	@docker run --rm \
		--network keydb_valkey_db_ha \
		-v $(CURDIR)/bin/redis-shake.toml:/tmp/redis-shake.toml:ro \
		6run0/redis-shake:latest \
		redis-shake /tmp/redis-shake.toml
	@echo ""
	@echo "=== 3. Проверка миграции ==="
	@echo "  KeyDB  DBSIZE: $$(docker exec keydb_node1 keydb-cli -a pass DBSIZE 2>&1 | grep -v Warning)"
	@echo "  Cluster DBSIZE:"
	@for node in valkey_node1 valkey_node2 valkey_node3; do \
		echo "    $$node: $$(docker exec $$node valkey-cli -a pass DBSIZE 2>&1 | grep -v Warning)"; \
	done
	@echo ""
	@echo "✅ Миграция в кластер завершена"
	@echo "  Подключайте PHP-приложение к кластеру через RedisCluster"
