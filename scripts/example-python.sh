#!/bin/bash

DIR="/opt/shvirtd-example-python-mia"
SRC_URL="https://github.com/murtazinilyas/shvirtd-example-python-mia.git"
APP_URL="http://127.0.0.1:8090"
ORIG_DIR="$PWD"

echo "Starting script"

if [ -d "$DIR" ]; then
    echo "Destroying existing app"
    cd "$DIR"
    docker compose down
    cd "$ORIG_DIR"
    rm -rf "$DIR"
fi

echo "Clear all docker resources"
docker system prune -f
docker volume prune -f
docker network prune -f

echo "Cloning app from $SRC_URL"
git clone "$SRC_URL" "$DIR"

echo "Starting app"
cd "$DIR"
docker compose up -d

echo "Waiting until db is ready"
sleep 30

i=0

for i in {1..5}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL")
    if [ "$STATUS" -eq 200 ]; then
        echo "App is ready"
        break
    else
        echo "App is not ready"
    fi
    sleep 10
    if [ "$i" -eq 5 ]; then
        echo "Something went wrong, checking logs"
        docker logs mia-db || true
        docker logs mia-python || true
        exit 1
    fi
done

echo "App started successfully"
