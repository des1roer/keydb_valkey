DOCKER_COMP = docker-compose --env-file=.env --env-file=.env.local

default: up

up:
	@ bash -c 'if [ ! -f ".env.local" ] ; then cp .env.local.dist .env.local; fi;'
	@$(DOCKER_COMP) up -d

d: down

down:
	@$(DOCKER_COMP) down

build:
	@$(DOCKER_COMP) build

ps:
	@$(DOCKER_COMP) ps

kdb:
	@$(DOCKER_COMP) exec -u 0 keydb_ha_test bash
