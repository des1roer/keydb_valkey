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

# ── VALKEY ──
val-primary:
	@$(DOCKER_COMP) exec valkey_primary bash
val-replica:
	@$(DOCKER_COMP) exec valkey_replica bash
val-sentinel:
	@$(DOCKER_COMP) exec valkey_sentinel bash

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

# ── DATA MIGRATION ──
# KeyDB → Valkey: stop Valkey, replace dump.rdb, restart (auto-load)
migrate-data:
	@echo "=== 1. KeyDB: DBSIZE до миграции ==="
	@docker exec keydb_node1 keydb-cli -a pass DBSIZE 2>&1 | grep -v Warning
	@echo ""
	@echo "=== 2. KeyDB: BGSAVE (сохраняем дамп) ==="
	@docker exec keydb_node1 keydb-cli -a pass BGSAVE 2>&1 | grep -v Warning
	@echo "  Ждём завершения dump..."
	@sleep 3
	@echo ""
	@echo "=== 3. Копируем dump.rdb на хост ==="
	@docker cp keydb_node1:/data/dump.rdb ./dump.rdb 2>&1 && \
		echo "  dump.rdb скопирован, размер: $$(ls -lh ./dump.rdb | awk '{print $$5}')" || \
		(echo "  ОШИБКА: не удалось скопировать dump.rdb"; exit 1)
	@echo ""
	@echo "=== 4. Останавливаем valkey_primary ==="
	@docker stop valkey_primary 2>&1 && \
		echo "  valkey_primary остановлен" || \
		(echo "  ОШИБКА: не удалось остановить valkey_primary"; exit 1)
	@echo ""
	@echo "=== 5. Копируем dump.rdb в valkey_primary ==="
	@docker cp ./dump.rdb valkey_primary:/data/dump.rdb 2>&1 && \
		echo "  dump.rdb размещён в контейнере" || \
		(echo "  ОШИБКА: не удалось разместить dump.rdb"; exit 1)
	@echo ""
	@echo "=== 6. Запускаем valkey_primary (автозагрузка dump.rdb) ==="
	@docker start valkey_primary 2>&1 && \
		echo "  valkey_primary запущен" || \
		(echo "  ОШИБКА: не удалось запустить valkey_primary"; exit 1)
	@echo "  Ждём загрузки данных..."
	@sleep 3
	@echo ""
	@echo "=== 7. Проверка результата ==="
	@echo "  KeyDB  DBSIZE: $$(docker exec keydb_node1 keydb-cli -a pass DBSIZE 2>&1 | grep -v Warning)"
	@echo "  Valkey DBSIZE: $$(docker exec valkey_primary valkey-cli -a pass DBSIZE 2>&1 | grep -v Warning)"
	@echo ""
	@echo "=== 8. Очистка ==="
	@rm -f ./dump.rdb && echo "  ./dump.rdb удалён"
	@echo ""
	@echo "✅ Миграция завершена. Дальше:"
	@echo "   make migrate-to-valkey   # переключить трафик на Valkey"
	@echo "   make migrate-to-keydb    # вернуть обратно на KeyDB"
