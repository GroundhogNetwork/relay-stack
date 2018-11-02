#!/bin/bash

function stack-up {
    echo "check networks"
    netcheck=$(docker network ls -f 'name=safe-relay' -q)
    if [ -z $netcheck ]; then
        echo "creating network"
        docker network create safe-relay
    fi

    echo -e "Checking ganache..."
    if [ ! "$(docker-compose ps --filter state=up ganache)" ]; then
        echo -n "Checking ganache...Failed."
        exit
    else
        echo -n "Checking ganache...Success."
    fi

    echo -e "\nChecking redis..."
    if [ ! "$(docker-compose ps --filter state=up redis)" ]; then
        echo -n "Checking redis...Failed."
        exit
    else
        echo -n "Checking redis...Success."
    fi

    echo -e "\nChecking postgres..."
    if [ ! "$(docker-compose ps --filter state=up db)" ]; then
        echo -n "Checking postgres...Failed."
        exit
    else
        echo -n "Checking postgres...Success."
    fi

    echo "Start up services"
    docker-compose -f safe-notification.yml -f safe-relay.yml -f safe-transaction.yml -p safe-stack up -d
}

function stack-down {
    docker-compose -f safe-transaction.yml -f safe-notification.yml -f safe-relay.yml -p safe-stack down
}

function base-up {
    echo "Start up redis & databases"
    docker-compose -f docker-compose.yml -p safe-base up -d
    MNEMONIC=$(docker-compose logs ganache |grep Mnemonic: | cut -d ':' -f2 | sed -e 's/^[ \t]*//')
    docker build -t truffle truffle/
    docker run --network safe-relay -v truffle-data:/safe-contracts/build/ truffle truffle migrate
}

function base-down {
    docker-compose -f docker-compose.yml -p safe-base down --remove-orphans
}

function base-restart {
    base-down
    base-up
}

function status {
    docker-compose -f safe-transaction.yml -f safe-notification.yml -f safe-relay.yml -p safe-stack ps
    docker-compose -f docker-compose.yml -p safe-base ps
    echo "Transaction-History service: http://localhost:$(docker port safe-stack_web-transaction_1 | grep 27017 | cut -d ':' -f2)"
    echo "Notification service: http://localhost:$(docker port safe-stack_web-notification_1 | grep 27017 | cut -d ':' -f2)"
    echo "Relay service: http://localhost:$(docker port safe-stack_web-relay_1 | grep 27017 | cut -d ':' -f2)"
}

function clean_dbs {
    docker run -it -v $(pwd):/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/remove_dbs.sql"
    docker run -it -v $(pwd):/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/create_dbs.sql"
    down
    up
    down
    up
    say "Done Cleaning"
}

function init {
    echo "Start up redis & databases"
    alias run-stack="$(pwd)/run-stack.sh"
    base-down && stack-down
    docker network rm safe-relay && docker network create safe-relay
    base-up
    sleep 5
    docker run -it -v $(pwd):/scripts --rm --network safe-relay postgres:10-alpine psql -h db -U postgres -f "/scripts/remove_dbs.sql"
    docker run -it -v $(pwd):/scripts --rm --network safe-relay postgres:10-alpine psql -h db -U postgres -f "/scripts/create_dbs.sql"
    echo "Start Stack with: ./run-stack.sh up"
    echo "Add the following to your bash profile: alias run-stack='$(pwd)/run-stack.sh'"
}

function swagger {
    echo "Opening Swagger GUIs"
    open "http://localhost:$(docker port safe-stack_web-transaction_1 | grep 27017 | cut -d ':' -f2)"
    open "http://localhost:$(docker port safe-stack_web-notification_1 | grep 27017 | cut -d ':' -f2)"
    open "http://localhost:$(docker port safe-stack_web-relay_1 | grep 27017 | cut -d ':' -f2)"
}

function stack-restart {
    stack-down
    stack-up
}

"$@"