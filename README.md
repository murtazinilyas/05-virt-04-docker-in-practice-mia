# Домашнее задание к занятию 5. «Практическое применение Docker»

## Задача 1
1. Сделайте в своем GitHub пространстве fork [репозитория](https://github.com/netology-code/shvirtd-example-python).
2. Создайте файл ```Dockerfile.python``` на основе существующего `Dockerfile`:
   - Используйте базовый образ ```python:3.12-slim```
   - Обязательно используйте конструкцию ```COPY . .``` в Dockerfile
   - Создайте `.dockerignore` файл для исключения ненужных файлов
   - Используйте ```CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]``` для запуска
   - Протестируйте корректность сборки
 
2.1 Используйте multistage сборку вместо single stage.

3. (Необязательная часть, *) Изучите инструкцию в проекте и запустите web-приложение без использования docker, с помощью venv. (Mysql БД можно запустить в docker run).
4. (Необязательная часть, *) Изучите код приложения и добавьте управление названием таблицы через ENV переменную.

## Решение 1

```Dockerfile
FROM python:3.12-slim AS builder

#  Ваш код здесь #
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim AS worker

WORKDIR /app
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
COPY . .
EXPOSE 5000

# Запускаем приложение с помощью uvicorn, делая его доступным по сети
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
```

---
### ВНИМАНИЕ!
!!! В процессе последующего выполнения ДЗ НЕ изменяйте содержимое файлов в fork-репозитории! Ваша задача ДОБАВИТЬ 5 файлов: ```Dockerfile.python```, ```compose.yaml```, ```.gitignore```, ```.dockerignore```,```bash-скрипт```. Если вам понадобилось внести иные изменения в проект - вы что-то делаете неверно!
---

## Задача 2 (*)
1. Создайте в yandex cloud container registry с именем "test" с помощью "yc tool" . [Инструкция](https://cloud.yandex.ru/ru/docs/container-registry/quickstart/?from=int-console-help)
2. Настройте аутентификацию вашего локального docker в yandex container registry.
3. Соберите и залейте в него образ с python приложением из задания №1.
4. Просканируйте образ на уязвимости.
5. В качестве ответа приложите отчет сканирования.

![2](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t2.png)

## Задача 3
1. Изучите файл "proxy.yaml"
2. Создайте в репозитории с проектом файл ```compose.yaml```. С помощью директивы "include" подключите к нему файл "proxy.yaml".
3. Опишите в файле ```compose.yaml``` следующие сервисы: 

- ```web```. Образ приложения должен ИЛИ собираться при запуске compose из файла ```Dockerfile.python``` ИЛИ скачиваться из yandex cloud container registry(из задание №2 со *). Контейнер должен работать в bridge-сети с названием ```backend``` и иметь фиксированный ipv4-адрес ```172.20.0.5```. Сервис должен всегда перезапускаться в случае ошибок.
Передайте необходимые ENV-переменные для подключения к Mysql базе данных по сетевому имени сервиса ```web``` 

- ```db```. image=mysql:8. Контейнер должен работать в bridge-сети с названием ```backend``` и иметь фиксированный ipv4-адрес ```172.20.0.10```. Явно перезапуск сервиса в случае ошибок. Передайте необходимые ENV-переменные для создания: пароля root пользователя, создания базы данных, пользователя и пароля для web-приложения.Обязательно используйте уже существующий .env file для назначения секретных ENV-переменных!

2. Запустите проект локально с помощью docker compose , добейтесь его стабильной работы: команда ```curl -L http://127.0.0.1:8090``` должна возвращать в качестве ответа время и локальный IP-адрес. Если сервисы не стартуют воспользуйтесь командами: ```docker ps -a ``` и ```docker logs <container_name>``` . Если вместо IP-адреса вы получаете информационную ошибку --убедитесь, что вы шлете запрос на порт ```8090```, а не 5000.

5. Подключитесь к БД mysql с помощью команды ```docker exec -ti <имя_контейнера> mysql -uroot -p<пароль root-пользователя>```(обратите внимание что между ключем -u и логином root нет пробела. это важно!!! тоже самое с паролем) . Введите последовательно команды (не забываем в конце символ ; ): ```show databases; use <имя вашей базы данных(по-умолчанию virtd, как это указано в .env)>; show tables; SELECT * from requests LIMIT 10;```. Примечание: таблица в БД создается после первого поступившего запроса к приложению.

6. Остановите проект. В качестве ответа приложите скриншот sql-запроса.

Compose.yaml:

```YAML
include:
  - ./proxy.yaml

services:
  web:
    # build:
    #   context: .
    #   dockerfile: Dockerfile.python
    container_name: mia-python
    image: cr.yandex/crp8m8obdkmolgsfc3oc/mia-python:1
    expose:
      - 5000
    environment:
      - DB_HOST=172.20.0.10
      - DB_USER=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASSWORD}
      - DB_NAME=${MYSQL_DATABASE}
    networks:
      backend:
        ipv4_address: 172.20.0.5
    depends_on:
      - db
    restart: on-failure

  db:
    image: mariadb
    container_name: mia-db
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    networks:
      backend:
        ipv4_address: 172.20.0.10
    restart: on-failure
```

Для выполнения задания номер 5 пришлось немного отойти от условий задания: для БД использовал образ ```mariadb```, вместо ```mysql:8```, т.к. ```schnitzler/mysqldump``` не хотел работать с ним. 

![3-1](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t3.png)

![3-2](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t3-2.png)

## Задача 4
1. Запустите в Yandex Cloud ВМ (вам хватит 2 Гб Ram).
2. Подключитесь к Вм по ssh и установите docker.
3. Напишите bash-скрипт, который скачает ваш fork-репозиторий в каталог /opt и запустит проект целиком.
4. Зайдите на сайт проверки http подключений, например(или аналогичный): ```https://check-host.net/check-http``` и запустите проверку вашего сервиса ```http://<внешний_IP-адрес_вашей_ВМ>:8090```. Таким образом трафик будет направлен в ingress-proxy. Трафик должен пройти через цепочки: Пользователь → Internet → Nginx → HAProxy → FastAPI(запись в БД) → HAProxy → Nginx → Internet → Пользователь
5. (Необязательная часть) Дополнительно настройте remote ssh context к вашему серверу. Отобразите список контекстов и результат удаленного выполнения ```docker ps -a```
6. Повторите SQL-запрос на сервере и приложите скриншот и ссылку на fork.

Поднял машину и инициализировал yandex cloud container registry с помощью terraform. [Конфигурационне файлы terrafrom](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/tree/main/tf) 

Подождал, пока не установится docker из [метаданных](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/tf/cloud-init.yml), вошел по SSH на машину, в папке /opt создал скрипт [example-python.sh](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scripts/example-python.sh):

```bash
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
```

Результат:

![4](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t4.png)

## Задача 5 (*)
1. Напишите и задеплойте на вашу облачную ВМ bash скрипт, который произведет резервное копирование БД mysql в директорию "/opt/backup" с помощью запуска в сети "backend" контейнера из образа ```schnitzler/mysqldump``` при помощи ```docker run ...``` команды. Подсказка: "документация образа."
2. Протестируйте ручной запуск
3. Настройте выполнение скрипта раз в 1 минуту через cron, crontab или systemctl timer. Придумайте способ не светить логин/пароль в git!!
4. Предоставьте скрипт, cron-task и скриншот с несколькими резервными копиями в "/opt/backup"

Написал скрипт [backup.sh](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scripts/backup.sh):

```Bash
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
```

Запись в crontab:

```
*/1 * * * * /opt/backup.sh
```

Результат:

![5](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t5.png)

## Задача 6
Скачайте docker образ ```hashicorp/terraform:latest``` и скопируйте бинарный файл ```/bin/terraform``` на свою локальную машину, используя dive и docker save.
Предоставьте скриншоты  действий .

![6.0-1](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t6-0-1.png)

![6.0-2](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t6-2.png)

## Задача 6.1
Добейтесь аналогичного результата, используя docker cp.  
Предоставьте скриншоты  действий .

![6.1](https://github.com/murtazinilyas/05-virt-04-docker-in-practice-mia/blob/main/scshots/t6-1.png)
