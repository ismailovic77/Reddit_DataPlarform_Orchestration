ifdef ENV
	include ./envs/.env.$(ENV)
	export
endif

# start targets
.PHONY: start-spark start-infra start-all first-start

start-spark:                                 # target name
	./scripts/start_spark_cluster.sh                 # command to run (TAB indented)

start-infra:                                 # another target
	./scripts/start_infra_docker.sh 

first-start:
	docker compose up -d postgres 
	docker compose run --rm airflow-init

start-all: start-spark start-infra          # depends on both, runs them in order


# stop targets  
.PHONY: stop-spark stop-infra stop-all
stop-spark:
	./scripts/stop_spark_cluster.sh

stop-infra:
	./scripts/stop_infra_docker.sh

stop-all: stop-infra stop-spark

# utility targets
.PHONY: lint test clean