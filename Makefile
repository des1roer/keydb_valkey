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

# Quick shell into services
kdb-master:
	@$(DOCKER_COMP) exec -u 0 keydb_master bash
kdb-replica:
	@$(DOCKER_COMP) exec -u 0 keydb_replica bash
kdb-sentinel:
	@$(DOCKER_COMP) exec -u 0 keydb_sentinel bash

val-master:
	@$(DOCKER_COMP) exec -u 0 valkey_master bash
val-replica:
	@$(DOCKER_COMP) exec -u 0 valkey_replica bash
val-sentinel:
	@$(DOCKER_COMP) exec -u 0 valkey_sentinel bash

redis-master:
	@$(DOCKER_COMP) exec -u 0 redis_master bash
redis-replica:
	@$(DOCKER_COMP) exec -u 0 redis_replica bash
redis-sentinel:
	@$(DOCKER_COMP) exec -u 0 redis_sentinel bash
