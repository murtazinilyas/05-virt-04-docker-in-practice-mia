#!/bin/bash

FILE_COUNT="$(ls -l /opt/backup | grep .sql | wc -l)"

if [[ $FILE_COUNT == 10 ]]; then
  cd /opt/backup
  rm -rf $(ls -l | grep .sql | awk '{print $9}' | head -n 1)
  cd /opt
fi

now=$(date +"%s_%Y-%m-%d")
PASSWORD=$(awk -F'=' '{print $2}' /opt/shvirtd-example-python-mia/.env | sed 's/^"//;s/"$//' | tail -n 1)

docker run \
    --rm --entrypoint "" \
    -v /opt/backup:/backup \
    --link="mia-db" \
    --network="shvirtd-example-python-mia_backend" \
    schnitzler/mysqldump \
    mysqldump --opt -h mia-db -u app -p"$PASSWORD" "--result-file=/backup/${now}_dumps.sql" virtd
