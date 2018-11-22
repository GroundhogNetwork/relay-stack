#!/bin/bash

function relay {
    if [ "$1" == "up" ];
    then
        echo -ne 'check networks\r'
        netcheck=$(docker network ls -f 'name=safe-stack' -q)
        if [ -z $netcheck ]; then
            echo -ne 'creating network\r'
            docker network create safe-stack
        else
            echo -ne 'check networks...OK!\r'
        fi
        echo -ne '\n'

        echo -ne 'check for safe-relay\r'
        if [ ! -d safe-relay-service ]; then
            echo -ne 'check for safe-relay...MISSING!\r'
            echo -ne '\n'
            #Install gnosis-py package locally
            init --clean
        else
            echo -ne 'check for safe-relay...OK!\r'
        fi
        echo -ne '\n'

        echo -ne 'check for gnosis-package\r'
        if [ ! -d safe-relay-service/gnosis_package ]; then
            #Install gnosis-py package locally
            docker run -v $(pwd)/safe-relay-service/gnosis_package:/usr/local/lib/python3.6/site-packages/gnosis -it safe-relay_web:latest pip install --no-dependencies --force-reinstall gnosis-py
            echo -ne '\n'
        else
            echo -ne 'check for gnosis-package...OK!\r'
        fi

        echo -ne '\n'

        echo "Start up services"
        services=$2
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay up --no-deps -d $services
        sleep 5
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay up --no-deps -d scheduler
    elif [ "$1" == 'down' ]; 
    then
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay down
    elif [ "$1" == 'build' ]; 
    then
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay build $2
    elif [ "$1" == 'restart' ]; 
    then
        docker-compose -f safe-relay-service/docker-compose.yml -p safe-relay restart $2
    fi
}

function base {
    if [ "$1" == "up" ];
    then
        echo "check networks"
        netcheck=$(docker network ls -f 'name=safe-stack' -q)
        if [ -z $netcheck ]; then
            echo "creating network"
            docker network create safe-stack
        fi
        echo "Start up redis & databases"
        docker-compose -f docker-compose.yml -p safe-base up -d
    elif [ "$1" == 'down' ]; 
    then
        docker-compose -f docker-compose.yml -p safe-base down --remove-orphans
    elif [ "$1" == 'build' ]; 
    then
        docker-compose -f docker-compose.yml -p safe-base build $2
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
    docker run -it -v $(pwd)/scripts:/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/remove_dbs.sql"
    docker run -it -v $(pwd)/scripts:/scripts --rm --network safe-relay --link safe-stack_db_1 postgres:10-alpine psql -h db -U postgres -f "/scripts/create_dbs.sql"
    down
    up
    down
    up
    say "Done Cleaning"
}

function init {

    while getopts cd option
    do
    case "${option}"
    in
    c) clean="true";;
    d) debug="true";;
    esac
    done

    if [ "$debug" == "true" ]; then
        cmd="clean debug"
    else
        cmd="clean"
    fi

    if [ "$clean" == "true" ]; then
        eval $cmd
    fi

}
        
function clean {
        
        down

        while true; do
            read -p "Do you wish to clean your docker images?" yn
            case $yn in
                [Yy]* ) docker images -a | grep "safe" | awk '{print $3}' | xargs docker rmi -f; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done

        echo "Grabbing Relay Code"
        rm -rf safe-relay-service
        git clone --single-branch -b develop https://github.com/gnosis/safe-relay-service.git
        #cat docker/add-network.yaml >> safe-relay-service/docker-compose.yml
        echo "ptvsd==4.1.4" >> safe-relay-service/requirements.txt
        #sed -i "" -e '/gnosis-py/d' safe-relay-service/requirements.txt
        services="web worker scheduler nginx"
        if [ "$1" == "debug" ]; then fileappend="_$1"; services="web worker scheduler"; fi;
        /bin/cp -rf docker/relay/manage.py safe-relay-service/manage.py
        /bin/cp -rf docker/relay/relay$fileappend.yml safe-relay-service/docker-compose.yml
        /bin/cp -rf docker/relay/run_web$fileappend.sh safe-relay-service/docker/web/run_web.sh

        # Fix swagger
        sed -i "" -e $'/validators=/a\\\n'"\    url='http://localhost:8000'," safe-relay-service/config/urls.py
        # Build Tookentwo
        cd TookenTwo-StarringLiamNeesans
        rm -rf node_modules
        npm install
        npm install
        cd ..
        base build
        relay build "$services"
}

function swagger {
    echo "Opening Swagger GUIs"
    open "http://localhost:$(docker port safe-stack_web-transaction_1 | grep 27017 | cut -d ':' -f2)"
    open "http://localhost:$(docker port safe-stack_web-notification_1 | grep 27017 | cut -d ':' -f2)"
    open "http://localhost:$(docker port safe-stack_web-relay_1 | grep 27017 | cut -d ':' -f2)"
}

function stack-restart {
    base restart
    relay restart
}

function up {
    base up
    if [ "$1" == "debug" ]; then
        services="web worker"
    else
        services="web worker nginx"
    fi
    relay up "$services"
}

function down {
    base down
    relay down
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

"$@"