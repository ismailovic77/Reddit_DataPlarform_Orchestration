# start the docker ressource with docker compose 
# start postgres
#docker compose -f ./infra/docker-compose.uat.yml --env-file ./infra/.env.uat up -d postgres

#start the init process for airflow db migrate and admin user creation
#docker compose -f ./infra/docker-compose.uat.yml --env-file ./infra/.env.uat run --rm airflow-init

# start the services in the container 
docker compose up -d airflow-webserver airflow-scheduler minio