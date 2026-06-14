ifdef ENV
	include .env.$(ENV)
	export
endif

# start targets
.PHONY: start-spark start-infra start-all first-start
start-spark:                                 
	./scripts/start_spark_cluster.sh                

start-docker-infra:                                 
	docker compose --env-file .env.$(ENV) up -d airflow-webserver airflow-scheduler minio

first-start:
	docker compose --env-file .env.$(ENV) up -d postgres
	docker compose --env-file .env.$(ENV) run --rm airflow-init

start-all: start-spark  start-docker-infra         # depends on both, runs them in order


# stop targets  
.PHONY: stop-spark stop-infra stop-all
stop-spark:
	./scripts/stop_spark_cluster.sh

stop-docker-infra:
	docker compose --env-file .env.$(ENV) down

stop-all: stop-docker-infra stop-spark

#airflow command
.PHONY: add-connections
add-connections:
	envsubst < $(AIRFLOW_HOME)/connections/connections.yaml > $(AIRFLOW_HOME)/connections/connections_resolved.yaml
	airflow connections import --overwrite $(AIRFLOW_HOME)/connections/connections_resolved.yaml

#docker commands
.PHONY:
compose-build:
	docker compose build

	