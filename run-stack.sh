#!/bin/bash

function relay {
    if [ "$1" == "up" ];
    then

        echo "check networks"
        netcheck=$(docker network ls -f 'name=safe-stack' -q)
        if [ -z $netcheck ]; then
            echo "creating network"
            docker network create safe-stack
        fi
        echo "Start up services"
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay up --no-deps -d web worker nginx
        sleep 5
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay up --no-deps -d scheduler
    elif [ "$1" == 'down' ]; 
    then
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay down
    elif [ "$1" == 'restart' ]; 
    then
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay restart
    fi    
}

function stack-down {
    docker-compose -f safe-transaction.yml -f safe-notification.yml -f safe-relay.yml -p safe-stack down
}

function base {
    if [ "$1" == "up" ];
    then
        echo "Start up redis & databases"
        docker-compose -f docker-compose.yml -p safe-base up -d
    elif [ "$1" == 'down' ]; 
    then
        docker-compose -f docker-compose.yml -p safe-base down --remove-orphans
    elif [ "$1" == 'restart' ]; 
    then
        docker-compose -f docker-compose.yml -p safe-base restart
    fi
}

function status {
    docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay ps
    docker-compose -f docker-compose.yml -p safe-base ps
    #echo "Transaction-History service: http://localhost:$(docker port safe-stack_web-transaction_1 | grep 27017 | cut -d ':' -f2)"
    #echo "Notification service: http://localhost:$(docker port safe-stack_web-notification_1 | grep 27017 | cut -d ':' -f2)"
    echo "Relay service: http://localhost:$(docker port safe-relay_nginx_1 | cut -d ':' -f2)"
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

    if [ "$1" == "--clean" ];
    then
        echo "Grabbing Relay Code"
        rm -rf safe-relay-service
        git clone --single-branch -b develop https://github.com/gnosis/safe-relay-service.git
        cat docker/add-network.yaml >> safe-relay-service/docker-compose.yml 
    elif [ "$1" == "--update" ];
    then
        if [ ! -d safe-relay-service ]; then
            git clone --single-branch -b develop https://github.com/gnosis/safe-relay-service.git;
        fi
        cd safe-relay-service
        git pull
        cd ..
    else
        :
    fi
    #sleep 5
    #docker run -it -v $(pwd):/scripts --rm --network safe-relay postgres:10-alpine psql -h db -U postgres -f "/scripts/remove_dbs.sql"
    #docker run -it -v $(pwd):/scripts --rm --network safe-relay postgres:10-alpine psql -h db -U postgres -f "/scripts/create_dbs.sql"
    #echo "Start Stack with: ./run-stack.sh up"
    #echo "Add the following to your bash profile: alias run-stack='$(pwd)/run-stack.sh'"
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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

"$@"