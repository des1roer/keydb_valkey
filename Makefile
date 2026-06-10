DOCKER_COMP = docker-compose

default: up

up:
	@$(DOCKER_COMP) up -d

d: down

down:
	@$(DOCKER_COMP) down --remove-orphans

build:
	@$(DOCKER_COMP) build

ps:
	@$(DOCKER_COMP) ps

# ── KEYDB ──
kdb1:
	@$(DOCKER_COMP) exec keydb_node1 bash
kdb2:
	@$(DOCKER_COMP) exec keydb_node2 bash

# ── VALKEY CLUSTER (6 nodes: 3 primary + 3 replica) ──
val-node1:
	@$(DOCKER_COMP) exec valkey_node1 bash
val-node2:
	@$(DOCKER_COMP) exec valkey_node2 bash
val-node3:
	@$(DOCKER_COMP) exec valkey_node3 bash
val-node4:
	@$(DOCKER_COMP) exec valkey_node4 bash
val-node5:
	@$(DOCKER_COMP) exec valkey_node5 bash
val-node6:
	@$(DOCKER_COMP) exec valkey_node6 bash

# Создать кластер (запустить после make up)
val-cluster-create:
	@bash bin/create-cluster.sh

# Информация о кластере
val-cluster-info:
	@echo "=== Cluster Info ==="
	@docker exec valkey_node1 valkey-cli -a pass -c CLUSTER INFO 2>/dev/null | grep -v Warning
	@echo ""
	@echo "=== Cluster Nodes ==="
	@docker exec valkey_node1 valkey-cli -a pass -c CLUSTER NODES 2>/dev/null | grep -v Warning

# Проверка кластера
val-cluster-check:
	@docker run --rm --network keydb_valkey_db_ha \
		valkey/valkey:9 \
		valkey-cli --cluster check valkey_node1:6379 -a pass

# Подключение к кластеру (cluster-мод)
val-shell:
	@docker exec -it valkey_node1 valkey-cli -a pass -c

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
