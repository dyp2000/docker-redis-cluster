#!/usr/bin/env make

KEY1 = "undefined"
TEST_COUNT = 50000
OS := $(shell uname -s)

docker_bin := $(shell command -v docker 2> /dev/null)
docker_compose_bin := $(shell command -v docker-compose 2> /dev/null)

ifeq ($(OS), Darwin)
	echo_bin = $(shell command -v echo 2> /dev/null)
else
	echo_bin = $(shell command -v echo -e 2> /dev/null)
endif

.PHONY : help start stop
.DEFAULT_GOAL := help

help: ## Показать эту подсказку
	@$(echo_bin) "Тестовое задание для ER-Telecom"
	@$(echo_bin) "Выполнил: Парыгин Д.Ю (dyp2000@mail.ru)\n"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[33m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start: up ## Запустить проект
	$(eval MASTERS_COUNT = $(shell $(docker_bin) exec -t redis-master-1 redis-cli --cluster check 10.5.0.10:6379 | grep slaves. | wc -l))
	@if [ "$(MASTERS_COUNT)" == "1" ] ; then \
		$(echo_bin) "\n\033[33mREDIS CLUSER starting...\033[0m"; \
		$(docker_bin) exec -t redis-master-1 redis-cli --cluster create \
		10.5.0.10:6379 10.5.0.11:6379 10.5.0.12:6379 10.5.0.13:6379 10.5.0.14:6379 10.5.0.15:6379 \
		--cluster-replicas 1 --cluster-yes; \
	else \
		$(echo_bin) "\n\033[33mREDIS CLUSER already started...\033[0m"; \
	fi
	@$(echo_bin) "\n\033[33mМониторинг кластера:\033[0m http://localhost:8080/\n"

up: ## Поднять контейнеры
	$(docker_compose_bin) up --build -d

down: ## Остановить контейнеры
	$(docker_compose_bin) down

stop: down ## Остановить проект
	echo "Stop..."

info: ## Информация о кластере
	@$(echo_bin) "\n\033[33m<<< CLUSTER INFORMATION >>>\033[0m"
	$(docker_bin) exec -t redis-master-1 redis-cli cluster info
	@$(echo_bin) "\n\033[33m<<< CLUSTER NODES >>>\033[0m"
	$(docker_bin) exec -t redis-master-1 redis-cli cluster nodes

test: ## Тестирование кластера
	@$(docker_bin) exec -t redis-master-1 bash -c "echo -n 'Ожидание готовности кластера ..'; while ! redis-cli cluster info | grep cluster_state:ok >/dev/null 2>&1 ; do echo -n '.'; sleep 1; done; echo"
	@$(echo_bin) "\033[33mSet key1 in \"value1\" on redis-master-1 node...\033[0m"
	$(docker_bin) exec -t redis-master-1 redis-cli -c set key1 "value1"
	@$(echo_bin) "\033[33mGet key1 on redis-slave-3 node...\033[0m"
	@$(eval KEY1 = $(shell $(docker_bin) exec -t redis-slave-3 bash -c "redis-cli -c --raw get key1"))
	@if [ "$(KEY1)" != "undefined" ] ; then \
		$(echo_bin) "\033[32m<<< Test OK >>>\033[0m"; \
	else \
		$(echo_bin) "\033[31m<<< Test FAIL >>>\033[0m\nВ ключе \"key1\" ожидается значение \"value1\" - получено значение \"$(KEY1)\""; \
	fi
	@$(echo_bin) "\n\033[33mBenchmark REDIS-MASTER-1...\033[0m"
	$(docker_bin) exec redis-master-1 redis-benchmark -q -n $(TEST_COUNT)
	@$(echo_bin) "\033[33mBenchmark REDIS-MASTER-2...\033[0m"
	$(docker_bin) exec redis-master-2 redis-benchmark -q -n $(TEST_COUNT)
	@$(echo_bin) "\033[33mBenchmark REDIS-MASTER-3...\033[0m"
	$(docker_bin) exec redis-master-3 redis-benchmark -q -n $(TEST_COUNT)
	@$(echo_bin) "\033[33mBenchmark REDIS-SLAVE-1...\033[0m"
	$(docker_bin) exec redis-slave-1 redis-benchmark -q -n $(TEST_COUNT)
	@$(echo_bin) "\033[33mBenchmark REDIS-SLAVE-2...\033[0m"
	$(docker_bin) exec redis-slave-2 redis-benchmark -q -n $(TEST_COUNT)
	@$(echo_bin) "\033[33mBenchmark REDIS-SLAVE-3...\033[0m"
	$(docker_bin) exec redis-slave-3 redis-benchmark -q -n $(TEST_COUNT)

init: ## Инициализировать КЛАСТЕР
	$(docker_compose_bin) down
	rm -rf ./redis/master-1/*
	rm -rf ./redis/master-2/*
	rm -rf ./redis/master-3/*
	rm -rf ./redis/slave-1/*
	rm -rf ./redis/slave-2/*
	rm -rf ./redis/slave-3/*

clean: ## Удалить неиспользуемые контейнеры
	$(docker_bin) system prune -f

---------------: ## ---------------
