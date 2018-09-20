#!/bin/bash

function up {
    echo "check networks"
    netcheck=$(docker network ls -f 'name=safe-relay' -q)
    if [ -z $netcheck ]; then
        echo "creating network"
        docker network create safe-relay
    fi
    echo "Start up redis & databases"
    docker-compose -f docker-compose.yml up -d
    echo "Start up notification service"
    docker-compose -f safe-notification-service/docker-compose.yml up -d
    echo "Start up relay service"
    docker-compose -f safe-relay-service/docker-compose.yml up -d
    echo "Start up transaction history service"
    sleep 5
    docker-compose -f safe-transaction-history/docker-compose.yml up -d
}

function down {
    docker-compose -f safe-transaction-history/docker-compose.yml down --remove-orphans
    docker-compose -f safe-notification-service/docker-compose.yml down --remove-orphans
    docker-compose -f safe-relay-service/docker-compose.yml down --remove-orphans
    docker-compose -f docker-compose.yml down --remove-orphans
}

function status {
    docker-compose -f safe-transaction-history/docker-compose.yml ps
    docker-compose -f safe-notification-service/docker-compose.yml ps
    docker-compose -f safe-relay-service/docker-compose.yml ps
    docker-compose -f docker-compose.yml ps
    echo "Transaction-History service: http://localhost:$(docker port safe-transaction-history_nginx_1 | cut -d ':' -f2)"
    echo "Notification service: http://localhost:$(docker port safe-notification-service_nginx_1 | cut -d ':' -f2)"
    echo "Relay service: http://localhost:$(docker port safe-relay-service_nginx_1 | cut -d ':' -f2)"
}

function clean_dbs {
    docker run -it -v $(pwd):/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/remove_dbs.sql"
    docker run -it -v $(pwd):/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/create_dbs.sql"
    down
    up
    down
    up
}

function init {
    down
    echo "Start up redis & databases"
    docker network rm safe-relay
    docker network create safe-relay
    docker-compose -f docker-compose.yml up -d
    sleep 5
    docker run -it -v $(pwd):/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/remove_dbs.sql"
    docker run -it -v $(pwd):/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/create_dbs.sql"
    docker-compose -f docker-compose.yml down --remove-orphans
    echo "Generating db Tables..."
    up
    sleep 5
    echo "Cycling Stack..."
    down
    echo "Start Stack with: ./run-stack.sh up"
}

function open-swagger {
    echo "Opening Swagger GUIs"
    open "http://localhost:$(docker port safe-transaction-history_nginx_1 | cut -d ':' -f2)"
    open "http://localhost:$(docker port safe-notification-service_nginx_1 | cut -d ':' -f2)"
    open "http://localhost:$(docker port safe-relay-service_nginx_1 | cut -d ':' -f2)"
}

"$@"