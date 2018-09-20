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
}

$@