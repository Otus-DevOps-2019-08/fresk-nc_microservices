# fresk-nc_microservices
fresk-nc microservices repository

## Homework 12. Технология контейнеризации. Введение в Docker.

Создал папку `docker-monolith`.

Установил `docker`, `docker-compose`, `docker-machine`:
```
brew cask install docker
brew link docker
```

Запустил первый контейнер:
```
docker run hello-world
```

> Команда run создает и запускает контейнер из образа.

Список запущенных контейнеров:
```
dcoker ps
```

Список всех контейнеров:
```
docker ps -a
```

Список образов:
```
docker images
```

Запустил:
```
docker run -it ubuntu:16.04 /bin/bash
root@95472fea1e43:/#  echo 'Hello world!' > /tmp/file
root@95472fea1e43:/# exit
```

```
docker run -it ubuntu:16.04 /bin/bash
root@fe09c7201cb9:/# cat /tmp/file
cat: /tmp/file: No such file or directory
root@fe09c7201cb9:/# exit
```

Docker run каждый раз запускается новый контейнер.

Если не указывать флаг `--rm`, то после остановки контейнер вместе с содержимым 
остается на диске. 

Нашел ранее созданный контейнер в котором создал /tmp/file:
```
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}"

CONTAINER ID        IMAGE                                  CREATED AT                      NAMES
fe09c7201cb9        ubuntu:16.04                           2019-11-04 15:25:04 +0300 MSK   eloquent_goodall
95472fea1e43        ubuntu:16.04                           2019-11-04 15:24:32 +0300 MSK   romantic_cori
dbbe0a319d7e        hello-world                            2019-11-04 15:13:06 +0300 MSK   cool_grothendieck
```

Это предполседний контейнер запущенный из `ubuntu:16.04`, т.е. `container_id = fe09c7201cb9`.

Запустил этот контейнер:
```
docker start 95472fea1e43
```

`docker start` запускает остановленный контейнер.

Подсоединился к этому контейнеру:
```
docker attach 95472fea1e43
root@95472fea1e43:/# cat /tmp/file
Hello world!

Ctrl + p, Ctrl + q
```

```
docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
95472fea1e43        ubuntu:16.04        "/bin/bash"         7 minutes ago       Up 2 minutes                            romantic_cori
```

`docker attach` подсоединяет терминал к созданному контейнеру.

* `docker run = docker create + docker start + docker attach*`
* `docker create` используется, когда не нужно стартовать контейнер сразу
* в большинстве случаев используется `docker run`

`*`  при наличии опции -i

`docker run`

* Через параметры передаются лимиты(cpu/mem/disk), ip, volumes 
* -i – запускает контейнер в foreground режиме (docker attach) 
* -d – запускает контейнер в background режиме
* -t создает TTY  

`docker exec` Запускает новый процесс внутри контейнера, например,
bash внутри контейнера с приложением.

```
docker exec -it fe09c7201cb9 bash
root@fe09c7201cb9:/# ps axf
  PID TTY      STAT   TIME COMMAND
   10 pts/1    Ss     0:00 bash
   20 pts/1    R+     0:00  \_ ps axf
    1 pts/0    Ss+    0:00 /bin/bash
root@fe09c7201cb9:/# exit
```

`docker commit` создает образ из контейнера, контейнер при этом остается запущенным.

```
docker commit fe09c7201cb9 fresk/ubuntu-tmp-file

06f635d13946e1b0543c7115f123824a61d5b982c2c2027aedd8e4daa544351b
```

```
docker images

REPOSITORY                      TAG                 IMAGE ID            CREATED             SIZE
fresk/ubuntu-tmp-file           latest              06f635d13946        25 seconds ago      123MB
```

docker kill & stop
* kill сразу посылает SIGKILL
* stop посылает SIGTERM, и через 10 секунд(настраивается) посылает SIGKILL
* SIGTERM - сигнал остановки приложения
* SIGKILL - безусловное завершение процесса

```
docker ps -q

fe09c7201cb9

docker kill $(docker ps -q)

fe09c7201cb9
```

docker system df
* Отображает сколько дискового пространства занято образами, контейнерами и volume’ами
* Отображает сколько из них не используется и возможно удалить

```
docker system df

TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              6                   3                   903.6MB             232MB (25%)
Containers          139                 0                   707.7MB             707.7MB (100%)
Local Volumes       0                   0                   0B                  0B
Build Cache         0                   0                   0B                  0B
```

docker rm & rmi
* rm удаляет контейнер, можно добавить флаг -f,
чтобы удалялся работающий container(будет послан sigkill)
* rmi удаляет image, если от него не зависят запущенные контейнеры

Удалил все незапущенные контейнеры
```
docker rm $(docker ps -a -q) 
```

Удалил все образы
```
docker rmi $(docker images -q) 
```

### docker-machine

* docker-machine - встроенный в докер инструмент для создания хостов и установки на
них docker engine. Имеет поддержку облаков и систем виртуализации (Virtualbox, GCP и
др.)
* Команда создания - docker-machine create <имя>. Имен может быть много, переключение
между ними через eval $(docker-machine env <имя>). Переключение на локальный докер -
eval $(docker-machine env --unset). Удаление - docker-machine rm <имя>.
* docker-machine создает хост для докер демона со указываемым образом в --googlemachine-image,
в ДЗ используется ubuntu-16.04. Образы которые используются для
построения докер контейнеров к этому никак не относятся.
* Все докер команды, которые запускаются в той же консоли после eval $(docker-machine env <имя>)
работают с удаленным докер демоном в GCP.

Создал новый проект `docker` в GCE

Запустил `gcloud init`, создал конфигурацию для нового проекта.

Авторизовался
```
gcloud auth application-default login
```

Создал докер-хост:
```
export GOOGLE_PROJECT=docker-258014

docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host
 
docker-machine ls
 NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
 docker-host   -        google   Running   tcp://35.240.35.125:2376           v19.03.4
```

Переключился на созданный хост:
```
eval $(docker-machine env docker-host)
```

Добавил в проект `start.sh`, `db_config` и `mongod.conf`.

Создал `Dockerfile`:
```
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
    build-essential \
    mongodb-server \
    ruby-full \
    ruby-dev \
    git
RUN gem install bundler
RUN git clone -b monolith https://github.com/express42/reddit.git

COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

RUN cd /reddit && bundle install
RUN chmod 0777 /start.sh

CMD ["/start.sh"]
```

Собрал образ:
```
docker build -t reddit:latest .
```

Запустил контейнер:
```
docker run --name reddit -d --network=host reddit:latest
```

Разрешил трафик на порт 9292:
```
gcloud compute firewall-rules create reddit-app \
 --allow tcp:9292 \
 --target-tags=docker-machine \
 --description="Allow PUMA connections" \
 --direction=INGRESS
 ```

Открыл приложение по адресу `http://35.240.35.125:9292`

### Docker hub

[Docker hub](https://hub.docker.com) - это облачный registry сервис от компании Docker.
В него можно выгружать и загружать из него докер образы. Docker по
умолчанию скачивает образы из докер хаба. 

Авторизовался в Docker hub.
```
docker login
```

Запушил свой образ:
```
docker tag reddit:latest fresk/otus-reddit:1.0
docker push fresk/otus-reddit:1.0
```

Выполнил в другой консоли:
```
docker run --name reddit -d -p 9292:9292 fresk/otus-reddit:1.0
```

Проверил, что приложение открывается локально `http://127.0.0.1:9292`.

## Homework 13. Docker-образы. Микросервисы.

[Рекомендуемые правила по написанию докерфайлов](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

Подключился к ранее созданному докер хосту
```
docker-machine ls

NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   *        google   Running   tcp://35.240.35.125:2376           v19.03.4

eval $(docker-machine env docker-host)
```

Скачал проект с архивом и распаковал его в папку src.

Создал post-py/Dockerfile:
```
FROM python:3.6.0-alpine

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

WORKDIR /app
COPY . /app

RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
    && pip install -r /app/requirements.txt \
    && apk del --virtual .build-deps gcc musl-dev

ENTRYPOINT ["python3", "post_app.py"]
```

Создал comment/Dockerfile:
```
FROM ruby:2.2

ENV APP_HOME /app
ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

RUN apt-get update -qq && apt-get install -y build-essential

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

CMD ["puma"]
```

Создал ui/Dockerfile
```
FROM ruby:2.2

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292
ENV APP_HOME /app

RUN apt-get update -qq && apt-get install -y build-essential

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

CMD ["puma"]
```

Скачал последний образ MongoDB:
```
docker pull mongo:latest
```

Собрал образы:
```
cd src
docker build -t fresk/post:1.0 ./post-py
docker build -t fresk/comment:1.0 ./comment
docker build -t fresk/ui:1.0 ./ui
```

Создал сеть:
```
docker network create reddit
```

Запустил контейнеры:
```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post fresk/post:1.0
docker run -d --network=reddit --network-alias=comment fresk/comment:1.0
docker run -d --network=reddit -p 9292:9292 fresk/ui:1.0
```

Образы очень много весят:
```
docker images

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
fresk/ui            1.0                 84278b545bd2        6 minutes ago       783MB
fresk/comment       1.0                 0df9e19a3a17        7 minutes ago       780MB
fresk/post          1.0                 e560a7bfbc7c        10 minutes ago      109MB
```

Улучшил докер-образ для ui:
```
FROM ubuntu:16.04

ENV APP_HOME /app
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

RUN apt-get update \
    && apt-get install -y ruby-full ruby-dev build-essential \
    && gem install bundler --no-ri --no-rdoc

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle install
COPY . $APP_HOME

CMD ["puma"]
```

Пересобрал
```
docker build -t fresk/ui:2.0 ./ui
```

Размер уменьшился:
```
docker images
REPOSITORY          TAG                 IMAGE ID            CREATED                  SIZE
fresk/ui            2.0                 61b9a4fdb3c9        Less than a second ago   459MB
```

Выключил и запустил контейнеры:
```
docker kill $(docker ps -q)
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post fresk/post:1.0
docker run -d --network=reddit --network-alias=comment fresk/comment:1.0
docker run -d --network=reddit -p 9292:9292 fresk/ui:2.0
```

Созданные посты не сохраняются после перезапуска.

Создал docker volume:
```
docker volume create reddit_db
```

Выключил и запустил контейнеры:
```
docker kill $(docker ps -q)
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post fresk/post:1.0
docker run -d --network=reddit --network-alias=comment fresk/comment:1.0
docker run -d --network=reddit -p 9292:9292 fresk/ui:2.0
```

> Подключил volume для mongodb `-v reddit_db:/data/db`

Теперь посты остаются после перезапуска.

Переключился обратно на локальный докер:
```
eval $(docker-machine env --unset)
```

## Homework 14. Docker-образы. Микросервисы.

Подключился к ранее созданному докер хосту

```
docker-machine ls

NAME          ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
docker-host   -        google   Running   tcp://35.240.35.125:2376           v19.03.4

eval $(docker-machine env docker-host)
```

### Работа с сетью

#### None network driver

```
docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig

Status: Downloaded newer image for joffotron/docker-net-tools:latest
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

Видно, что существует один сетевой интерфейс - Loopback.
Сетевой стек самого контейнера работает (ping localhost),
но без возможности контактировать с внешним миром.
Подходит для тестирования.

#### Host network driver

```
docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig

br-879b5e5dba3c Link encap:Ethernet  HWaddr 02:42:81:4E:1E:D2
          inet addr:172.18.0.1  Bcast:172.18.255.255  Mask:255.255.0.0
          inet6 addr: fe80::42:81ff:fe4e:1ed2%32555/64 Scope:Link
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:36 errors:0 dropped:0 overruns:0 frame:0
          TX packets:47 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:5459 (5.3 KiB)  TX bytes:5915 (5.7 KiB)

docker0   Link encap:Ethernet  HWaddr 02:42:06:79:4F:15
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          inet6 addr: fe80::42:6ff:fe79:4f15%32555/64 Scope:Link
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:22537 errors:0 dropped:0 overruns:0 frame:0
          TX packets:25113 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1635056 (1.5 MiB)  TX bytes:385744527 (367.8 MiB)

ens4      Link encap:Ethernet  HWaddr 42:01:0A:84:00:02
          inet addr:10.132.0.2  Bcast:10.132.0.2  Mask:255.255.255.255
          inet6 addr: fe80::4001:aff:fe84:2%32555/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1460  Metric:1
          RX packets:412597 errors:0 dropped:0 overruns:0 frame:0
          TX packets:371704 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1131373498 (1.0 GiB)  TX bytes:276893760 (264.0 MiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1%32555/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:1428698 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1428698 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:193767841 (184.7 MiB)  TX bytes:193767841 (184.7 MiB)
```

Соответствует выводу команды `docker-machine ssh docker-host ifconfig`

Выполнил на докер хосте, чтобы видеть список namespace:
```
docker-machine ssh docker-host sudo ln -s /var/run/docker/netns /var/run/netns
docker-machine ssh docker-host sudo ip netns

default
```

#### Bridge network driver

Создал bridge-сеть:
```
docker network create reddit --driver bridge 
```

> флаг --driver указывать не обязательно, т.к. по-умолчанию используется bridge

Запустил проект:
```
docker run -d --network=reddit mongo:latest
docker run -d --network=reddit fresk/post:1.0
docker run -d --network=reddit fresk/comment:1.0
docker run -d --network=reddit -p 9292:9292 fresk/ui:1.0
```

При открытие приложения в браузере получил ошибку
```
Can't show blog posts, some problems with the post service. Refresh?
```

Сервисы ссылаются друг на друга по dns именам, прописанным в ENV-переменных (см Dockerfile).
В текущей инсталляции встроенный DNS docker не знает ничего об этих
именах.

Решением проблемы будет присвоение контейнерам имен или
сетевых алиасов при старте:
```
--name <name> (можно задать только 1 имя)
--network-alias <alias-name> (можно задать множество алиасов)
```

Остановил старые контейнеры и запустил новые:
```
docker kill $(docker ps -q)
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post fresk/post:1.0
docker run -d --network=reddit --network-alias=comment  fresk/comment:1.0
docker run -d --network=reddit -p 9292:9292 fresk/ui:1.0
```

Теперь все хорошо.

Попробуем запустить проект в двух bridge сетях, чтобы ui не имел доступа к db.

Остановил контейнеры:
```
docker kill $(docker ps -q) 
```

Создал две сети:
```
docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24
```

Запустил контейнеры:
```
docker run -d --network=front_net -p 9292:9292 --name ui  fresk/ui:1.0
docker run -d --network=back_net --name comment fresk/comment:1.0
docker run -d --network=back_net --name post fresk/post:1.0
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest
```

При открытие приложения в браузере получил ошибку
```
Can't show blog posts, some problems with the post service. Refresh?
```

Docker при инициализации контейнера может подключить к нему только 1
сеть.
При этом контейнеры из соседних сетей не будут доступны как в DNS, так
и для взаимодействия по сети.

Поэтому нужно поместить контейнеры post и comment в обе сети.

Подключил контейнеры ко второй сети:
```
docker network connect front_net post
docker network connect front_net comment 
```

Теперь все хорошо.

Посмотрим, как выглядит сетевой стек Linux в текущий момент.

Зашел на докер-хост и установил `bridge-utils`:
```
docker-machine ssh docker-host
sudo apt-get update && sudo apt-get install bridge-utils
```

Выполнил
```
sudo docker network ls

NETWORK ID          NAME                DRIVER              SCOPE
3ad79515d36b        back_net            bridge              local
400bf450909a        bridge              bridge              local
a908dca911ec        front_net           bridge              local
714a9e81fee3        host                host                local
b9129fe3ebc1        none                null                local
879b5e5dba3c        reddit              bridge              local
```

Выполнил
```
ifconfig | grep br

br-3ad79515d36b Link encap:Ethernet  HWaddr 02:42:82:86:79:58
br-879b5e5dba3c Link encap:Ethernet  HWaddr 02:42:81:4e:1e:d2
br-a908dca911ec Link encap:Ethernet  HWaddr 02:42:d5:3c:7e:b8
```

Выполнил для первого bridge
```
brctl show br-3ad79515d36b

bridge name	        bridge id		    STP enabled	    interfaces
br-3ad79515d36b		8000.024282867958	no		        veth4c25bc5
							                            veth5e2abdd
							                            veth79dfb6d
```

Смотрим на iptables
```
sudo iptables -nL -t nat
```

Нас интересует цепочка `POSTROUTING`
```
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0
MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0
MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292
```

В ходе работы была необходимость публикации порта контейнера
UI (9292) для доступа к нему снаружи.
Посмотрим, что Docker при этом сделал в iptables:
```
Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292
```

Строчка `DNAT`.

Выполнил
```
ps ax | grep docker-proxy

10392 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
```

Видно, что запущен docker-proxy.

### Docker-compose

Проблемы:
* Одно приложение состоит из множества контейнеров/сервисов
* Один контейнер зависит от другого
* Порядок запуска имеет значение
* docker build/run/create … (долго и много)

docker-compose - отдельная утилита, позволяет декларативно описывать докер-инфраструктуры в yaml и
управлять многоконтейнерными приложениями.

Создал `src/docker-compose.yml`:
```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      - reddit
  ui:
    build: ./ui
    image: ${USERNAME}/ui:1.0
    ports:
      - 9292:9292/tcp
    networks:
      - reddit
  post:
    build: ./post-py
    image: ${USERNAME}/post:1.0
    networks:
      - reddit
  comment:
    build: ./comment
    image: ${USERNAME}/comment:1.0
    networks:
      - reddit

volumes:
  post_db:

networks:
  reddit:
```

Остановил контейнеры:
```
docker kill $(docker ps -q)
```

Экспортировал переменную `USERNAME`:
```
export USERNAME=fresk
```

Запустил контейнеры:
```
docker-compose up -d 
```

Смотрим список контейнеров:
```
docker-compose ps

    Name                  Command             State           Ports
----------------------------------------------------------------------------
src_comment_1   puma                          Up
src_post_1      python3 post_app.py           Up
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp
```

Добавил в docker-compose.yml несколько сетей, параметризовал версии сервисов и порт:
```
version: '3.3'
services:
  post_db:
    image: mongo:${VERSION_MONGODB}
    volumes:
      - post_db:/data/db
    networks:
      back_net:
        aliases:
          - post_db
          - comment_db
  ui:
    build: ./ui
    image: ${USERNAME}/ui:${VERSION_UI}
    ports:
      - ${UI_PORT}:${UI_PORT}/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${VERSION_POST}
    networks:
      - back_net
      - front_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:${VERSION_COMMENT}
    networks:
      - back_net
      - front_net

volumes:
  post_db:

networks:
  front_net:
  back_net:
```

Переменные окружения положил в `.env`.

Погасил контейнеры:
```
docker-compose down
```

Все контейнеры имеют префикс `src_`, он берется из названия папки в которой лежит
`docker-compose.yml`.

Есть два способа изменить префикс:
1. Задать перменную окружения `COMPOSE_PROJECT_NAME` - `COMPOSE_PROJECT_NAME=reddit`
2. При запуске указать флаг `-p` - `docker-compose -p reddit up -d`

### Задание со *

Создал docker-compose.override.yml, который позволяет изменять код каждого
из приложений без пересборки образов, и запускать puma в дебаг режиме с двумя воркерами.
```
version: '3.3'
services:
  ui:
    volumes:
      - ./ui:/app
    command: ["puma", "--debug", "--workers", "2"]
  post:
    volumes:
      - ./post-py:/app
  comment:
    volumes:
      - ./comment:/app
    command: ["puma", "--debug", "--workers", "2"]
```

### Полезные источники
* [https://docs.docker.com/compose/compose-file/](https://docs.docker.com/compose/compose-file/)

## Homework 15. Устройство Gitlab CI. Построение процесса непрерывной поставки

Создал новую виртуалку в GCP.
Подключился по ssh и поставил докер:
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-compose
```

Создал директории и docker-compose.yml:
```
sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
cd /srv/gitlab/
sudo touch docker-compose.yml
```

Содержимое docker-compose.yml:
```
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://35.195.1.87'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
```

Запустил docker-compose:
```
sudo docker-compose up -d 
```

Спустя минут 5 стал доступен интерфейс gitlab по адресу http://35.195.1.87

Ввел новый пароль для root и авторизовался.

Выключил регистрацию новых пользователей:
```
Admin Area -> Settings -> Sign-up restrictions -> Sign-up enabled
```

Создал новую группу проектов:
```
Groups -> New group
```

Создал проект:
```
New project
```

Запушил локальную ветку:
```
git checkout -b gitlab-ci-1
git remote add gitlab http://35.195.1.87/homework/example.git 
git push gitlab gitlab-ci-1
```

Добавил .gitlab-ci.yml:
```
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  script:
    - echo 'Building'

test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_job:
  stage: deploy
  script:
    - echo 'Deploy'
```

```
git add .gitlab-ci.yml
git commit -m 'add pipeline definition'
git push gitlab gitlab-ci-1 
```

Скопировал токен для регистрации раннера:
```
Settings -> CI/CD -> Runners -> Set up a specific Runner manually
```

На сервере с gitlab-ci запустил раннер:
```
sudo docker run -d --name gitlab-runner --restart always \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest
```

Зарегистрировал раннер:
```
sudo docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://35.195.1.87
Please enter the gitlab-ci token for this runner:
<TOKEN>
Please enter the gitlab-ci description for this runner:
[f538b5f4f686]: my-runner
Please enter the gitlab-ci tags for this runner (comma separated):
linux,xenial,ubuntu,docker
Registering runner... succeeded                     runner=ik_vvyva
Please enter the executor: docker-ssh+machine, kubernetes, custom, parallels, shell, ssh, virtualbox, docker+machine, docker, docker-ssh:
docker
Please enter the default Docker image (e.g. ruby:2.6):
alpine:latest
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

После добавления раннера, запустился ранее созданный пайплайн.

Добавил исходный код reddit в репозиторий:
```
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git 
git add reddit/
git commit -m 'Add reddit app'
git push gitlab gitlab-ci-1
```

Изменил описание пайплайна в .gitlab-ci.yml
```
image: ruby:2.4.2

stages:
...

variables:
 DATABASE_URL: 'mongodb://mongo/user_posts'
 
before_script:
 - cd reddit
 - bundle install

...
test_unit_job:
 stage: test
 services:
   - mongo:latest
 script:
   - ruby simpletest.rb
... 
``` 

Добавил файл reddit/simpletest.rb
```
require_relative './app'
require 'test/unit'
require 'rack/test'

set :environment, :test

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_get_request
    get '/'
    assert last_response.ok?
  end
end
```

Добавил библиотеку для тестирования в Gemfile
```
gem 'rack-test'
```

Запушил изменения

### Окружения

Изменим пайплайн таким образом, чтобы job deploy
стал определением окружения dev, на которое условно
будет выкатываться каждое изменение в коде проекта.

Переименовал stage deploy в review

Поправил джобу deploy_job
```
...
deploy_dev_job:
  stage: review
  script:
    - echo 'Deploy'
  environment:
    name: dev
    url: http://dev.example.com

```

Добавил stage и production которые будут запускаться по кнопке (`when manual`):

```
stages:
  ...
  - stage
  - production
  
staging:
  stage: stage
  when: manual
  script:
    - echo 'Deploy'
  environment:
    name: stage
    url: http://beta.example.com

production:
  stage: production
  when: manual
  script:
    - echo 'Deploy'
  environment:
    name: production
    url: http://example.com
```

Запушил изменения

Добавил ограничение для stage и production - должен стоять semver тег:
```
staging:
  stage: stage
  when: manual
  only:
    - /^\d+\.\d+\.\d+/
  script:
    - echo 'Deploy'
  environment:
    name: stage
    url: http://beta.example.com

production:
  stage: production
  when: manual
  only:
    - /^\d+\.\d+\.\d+/
  script:
    - echo 'Deploy'
  environment:
    name: production
    url: http://example.com
```

Теперь коммит без тега запустит пайплайн без джоб stage и production.
А добавление тега запустит полный пайплайн

### Динамические окружения

Gitlab CI позволяет определить динамические окружения, это мощная функциональность
позволяет иметь выделенный стенд для, например, каждой feature-ветки в git.

Определяются динамические окружения с помощью переменных, доступных в .gitlab-ci.yml

Добавил джобу, которая определяет динамическое окружение для каждой ветки в
репозитории, кроме ветки master:
```
branch review:
  stage: review
  script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
  environment:
   name: branch/$CI_COMMIT_REF_NAME
   url: http://$CI_ENVIRONMENT_SLUG.example.com
  only:
    - branches
  except:
    - master
```

Запуил изменения

### Задания со *

Добавил скрипт gitlab-ci/setup-runner.sh для создания раннера:
```
docker run -d --name gitlab-runner --restart always \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest

docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "$GITLAB_URL" \
    --registration-token "$GITLAB_REGISTRATION_TOKEN" \
    --executor "docker" \
    --docker-image alpine:latest \
    --description "docker-runner" \
    --tag-list "docker,alpine" \
    --run-untagged="true" \
    --locked="false" \
    --access-level="not_protected"
```

Добавил оповещения в slack.
https://app.slack.com/client/T6HR0TUP3/CN18S9CF5

### Полезные ссылки
* https://docs.gitlab.com/runner/install/docker.html
* https://docs.gitlab.com/runner/register/index.html#docker
* https://docs.gitlab.com/ee/user/project/integrations/slack.html

## Homework 16. Введение в мониторинг. Системы мониторинга.

Создал правило фаервола для Prometheus и Puma:

```
gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292
```

Создал докер хост в GCE и настроил локальное окружение на работу с ним:
```
export GOOGLE_PROJECT=docker-258014

docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host
    
eval $(docker-machine env docker-host)
```

Запустил контейнер с прометеусом:
```
docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0
```

Открыл веб-интерфейс по адресу `http://35.240.35.125:9090/graph`

> IP адрес можно узнать с помощью команды `docker-machine ip docker-host`

Остановил контейнер:
```
docker stop prometheus
```

Унес docker-monolith и docker-compose в папку docker. Создал папку monitoring.
В папке monitoring создал prometheus. В ней создал Dockerfile:
```
FROM prom/prometheus:v2.1.0
ADD prometheus.yml /etc/prometheus/
```

Создал файл `prometheus.yml`:
```
global:
  scrape_interval: '5s'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets:
        - 'localhost:9090'

  - job_name: 'ui'
    static_configs:
      - targets:
        - 'ui:9292'

  - job_name: 'comment'
    static_configs:
      - targets:
        - 'comment:9292'
```

Собрал образ:
```
cd monitoring/prometheus
export USER_NAME=fresk
docker build -t $USER_NAME/prometheus .
```

Выполнил сборку образов приложения:
```
cd ../../src/ui
bash docker_build.sh

cd ../post-py
bash docker_build.sh

cd ../comment
bash docker_build.sh
```

> Можно было проще - `for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done`

Добавил прометеус в docker-compose:
```
services:
...
  prometheus:
    image: ${USERNAME}/prometheus
    ports:
      - '9090:9090'
    volumes:
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention=1d'

volumes:
  prometheus_data:
```

Удалил `build` директивы из `docker_compose.yml`

Добавил всем сервисам сеть:
```
networks:
  - prometheus_net
```

В `.env` поправил версии образов на `latest`.

Запустил docker-compose:
```
cd docker
docker-compose up -d
```

### Мониторинг состояния микросервисов

#### Healthchecks

Healthcheck-и представляют собой проверки того, что
наш сервис здоров и работает в ожидаемом режиме.

Если сервис жив, то статус равен 1, иначе 0.

Вбил в интерфейсе прометеуса `ui_health`, нажал `execute`, получил:
```
ui_health{branch="monitoring-1",commit_hash="8376844",instance="ui:9292",job="ui",version="0.0.1"} 1
```

Остановил post `docker-compose stop post`

Опять выполнил `ui_health`, на этот раз получил:
```
ui_health{branch="monitoring-1",commit_hash="8376844",instance="ui:9292",job="ui",version="0.0.1"} 0
```

#### Поиск проблемы

Помимо статуса сервиса, мы также собираем статусы сервисов, от
которых он зависит. Названия метрик, значения которых соответствует
данным статусам, имеет формат ui_health_<service-name>. 

Наберем в строке выражений ui_health_ и Prometheus нам предложит
дополнить названия метрик.

Проверил ui_health_comment_availability, увидел, что статус не менялся.
Проверил ui_health_post_availability - статус изменился на 0.

Чиним проблему `docker-compose start post` :)

### Сбор метрик хоста

#### Exporters

Экспортер похож на вспомогательного агента для
сбора метрик.

В ситуациях, когда мы не можем реализовать
отдачу метрик Prometheus в коде приложения, мы
можем использовать экспортер, который будет
транслировать метрики приложения или системы в
формате доступном для чтения Prometheus.

Примеры: PostgreSQL, RabbitMQ, Nginx, Node exporter, cAdvisor

#### Node exporter 

Воспользуемся Node экспортер для сбора
информации о работе Docker хоста (виртуалки, где у
нас запущены контейнеры) и предоставлению этой
информации в Prometheus.

Node экспортер будем запускать также в контейнере. Определил еще один
сервис в `docker/docker-compose.yml` файле.

```
node-exporter:
  image: prom/node-exporter:v0.15.2
  networks:
    - prometheus_net
  user: root
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
    - /:/rootfs:ro
  command:
    - '--path.procfs=/host/proc'
    - '--path.sysfs=/host/sys'
    - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
```

Добавил в конфиг прометеуса:
```
- job_name: 'node'
  static_configs:
    - targets:
      - 'node-exporter:9100'
```

Собрал новый образ прометеуса:
```
cd monitoring/prometheus
docker build -t $USER_NAME/prometheus .
```

Пересоздал сервисы:
```
cd ../../docker
docker-compose down
docker-compose up -d
```

В списке endpoint-ов(Status -> Targets) прометеуса появился еще один endpoint.

Получил информацию об использовании ЦПУ - `node_load1`

Проверил нагрузку:
- зашел на машинку `docker-machine ssh docker-host`
- увеличил нагрузку `yes > /dev/null`
- мониторинг отобразил выросшую нагрузку

### Завершение работы

Запушил образы на docker-hub:

```
docker login
Login Succeeded

docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus 
```

- https://hub.docker.com/repository/docker/fresk/prometheus
- https://hub.docker.com/repository/docker/fresk/post
- https://hub.docker.com/repository/docker/fresk/ui
- https://hub.docker.com/repository/docker/fresk/otus-reddit

Удалил докер-хост:
```
docker-machine rm docker-host
```

## Homework 17. Мониторинг приложения и инфраструктуры

### Подготовка окружения

```
export GOOGLE_PROJECT=docker-258014

docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host

eval $(docker-machine env docker-host)
```

В docker-compose.yml описано приложение и прометеус, такое смешивание 
сущностей не очень хорошо.
Вынес прометеус в docker-compose-monitoring.yml

### [cAdvisor](https://github.com/google/cadvisor)

cAdvisor собирает информацию о ресурсах потребляемых
контейнерами и характеристиках их работы.

Добавил cAdvisor в docker-compose-monitoring.yml:
```
cadvisor:
  image: google/cadvisor:v0.29.0
  networks:
    - prometheus_net
  volumes:
    - '/:/rootfs:ro'
    - '/var/run:/var/run:rw'
    - '/sys:/sys:ro'
    - '/var/lib/docker/:/var/lib/docker:ro'
  ports:
    - '8080:8080'
```

Добавил cAdvisor в prometheus.yml:
```
- job_name: 'cadvisor'
  static_configs:
    - targets:
      - 'cadvisor:8080'
```

Пересобрал образ prometheus:
```
export USER_NAME=fresk
cd monitoring/prometheus
docker build -t $USER_NAME/prometheus .
```

Запустил сервисы:
```
cd ../../docker
docker-compose up -d
docker-compose -f docker-compose-monitoring.yml up -d
```

Добавил firewall правило для cadvisor:
```
gcloud compute firewall-rules create cadvisor-default --allow tcp:8080
```

Узнал ip виртуалки:
```
docker-machine ip docker-host
35.233.91.236
```

Открыл интерфейс cAdvisor по адресу http://35.233.91.236:8080

Нажал ссылку Docker Containers (внизу слева) для просмотра
информации по контейнерам.

По пути /metrics все собираемые метрики публикуются для
сбора Prometheus. Имена метрик контейнеров начинаются со слова
container.

### Grafana

Добавил grafana в docker-compose-monitoring.yml:
```
services:

  grafana:
    image: grafana/grafana:5.0.0
    networks:
      - prometheus_net
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secret
    depends_on:
      - prometheus
    ports:
      - 3000:3000

volumes:
  grafana_data:
```

Запустил новый сервис:
```
docker-compose -f docker-compose-monitoring.yml up -d grafana
```

Добавил firewall правило для grafana:
```
gcloud compute firewall-rules create grafana-default --allow tcp:3000
```

Открыл интерфейс grafana по адресу http://35.233.91.236:3000

Ввел логин и пароль из переменных окружение.

Нажал "Add data source", затем заполнил форму и сохранил:
```
Name: Prometheus Server
Type: Prometheus
URL: http://prometheus:9090
Access: Proxy
```

Перешел на сайт [grafana](https://grafana.com/grafana/dashboards), чтобы скачать
комьюнити дашборд. Нашел дашборд "Docker and system monitoring".
Нажал "Download JSON".

Перенес скаченный JSON в monitoring/grafana/dashboards.
Переименовал json в DockerMonitoring.json

Снова зашел в интерфейс grafana http://35.233.91.236:3000,
нажал "Create -> Import". Импортировал http://35.233.91.236:3000
В качестве источника данных выбрал Prometheus Server.

Добавил в prometheus.yml:
```
- job_name: 'post'
  static_configs:
    - targets:
      - 'post:5000'
```

Пересобрал образ Prometheus:
```
cd ../monitoring/prometheus
docker build -t $USER_NAME/prometheus .
```

Перезапустил инфраструктуру мониторинга:
```
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```

Создал несколько постов в приложении.

Открыл интерфейс grafana http://35.233.91.236:3000

Нажал "Create -> Dashboard -> Graph".
Создался пустой график. Нажал на его имя и "Edit".

На вкладке "Metrics" ввел в поле имя метрики `ui_request_count`.
На вкладке "General" ввел имя и описание графика.
Сохранил дашборд.

Добавил график ошибок - нажал "Add panel -> Graph".
На вкладке "Metrics" ввел в поле имя метрики `rate(ui_request_count{http_status=~"^[45].*"}[1m])`.
На вкладке "General" ввел имя и описание графика.
Сохранил дашборд.

> Использовал функцию `rate()`, чтобы посмотреть не просто значение
счетчика за весь период наблюдения, но и скорость увеличения 
данной величины за промежуток времени.

Видно, что первый график показывает просто счетчик запросов.
Переделал на `rate()` - `rate(ui_request_count[1m])`.

Добавил график 95-й процентиль для времени ответа - нажал "Add panel -> Graph".
На вкладке "Metrics" ввел в поле имя метрики `histogram_quantile(0.95, sum(rate(ui_request_response_time_bucket[5m])) by (le))`.
На вкладке "General" ввел имя и описание графика.
Сохранил дашборд.

Экспортировал дашборд в JSON файл,
который положил в monitoring/grafana/dashboards/UI_Service_Monitoring.json

Добавил еще один дашборд Business_Logic_Monitoring, с двумя графиками -
rate созданных постов и комментариев за 1 час. 
Экспортировал JSON в monitoring/grafana/dashboards/Business_Logic_Monitoring.json

### Алертинг

В Grafana есть alerting, но по функционалу он уступает Alertmanager в Prometheus.

Alertmanager - дополнительный компонент для системы
мониторинга Prometheus, который отвечает за первичную
обработку алертов и дальнейшую отправку оповещений по
заданному назначению.


Создал директорию monitoring/alertmanager, в ней создал Dockerfile:
```
FROM prom/alertmanager:v0.14.0
ADD config.yml /etc/alertmanager/
```

Добавил новый incoming webhook в слак https://my.slack.com/services/new/incoming-webhook в канал
#george_besedin, скопировал url - https://hooks.slack.com/services/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 

В monitoring/alertmanager создал config.yml:
```
global:
  slack_api_url: 'https://hooks.slack.com/services/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'

route:
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#george_besedin'
```

Собрал образ с Alertmanager:
```
cd ../monitoring/alertmanager
docker build -t $USER_NAME/alertmanager .
```

Добавил новый сервис в docker-compose-monitoring.yml:
```
alertmanager:
  image: ${USER_NAME}/alertmanager
  networks:
    - prometheus_net
  command:
    - '--config.file=/etc/alertmanager/config.yml'
  ports:
    - '9093:9093'
```

Создал alerts.yml в monitoring/prometheus:
```
groups:
  - name: alert.rules
    rules:
    - alert: InstanceDown
      expr: up == 0
      for: 1m
      labels:
        severity: page
      annotations:
        description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute'
        summary: 'Instance {{ $labels.instance }} down'
```

Создал простой алерт, который
будет срабатывать в ситуации, когда одна из наблюдаемых систем
(endpoint) недоступна для сбора метрик (в этом случае метрика up с
лейблом instance равным имени данного эндпоинта будет равна
нулю). 

Добавил операцию копирования данного файла в Dockerfile
monitoring/prometheus/Dockerfile:
```
ADD alerts.yml /etc/prometheus/
```

Добавил информацию о правилах в конфиг prometheus.yml:
```
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
```

Пересобрал образ prometheus:
```
cd ../prometheus
docker build -t $USER_NAME/prometheus .
```

Перезапустил инфраструктуру мониторинга:
```
cd ../../docker
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```

Алерты можно посмотреть в веб-интерфейсе Prometheus во вкладке Alerts.

#### Проверка алерта

Остановил один из сервисов:
```
docker-compose stop post
```

В слак пришло сообщение.

### Завершение работы

Запушил образы в докер-хаб:

```
docker login

docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus
docker push $USER_NAME/alertmanager
```

Удалил виртуалку
```
docker-machine rm docker-host
```

## Homework 18. Логирование и распределенная трассировка

### Подготовка окружения

```
export GOOGLE_PROJECT=docker-258014

docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging

eval $(docker-machine env logging)
```

Обновил код приложения, скачал из репозитория https://github.com/express42/reddit/tree/logging

Собрал новые образы `for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done`

### Логирование Docker контейнеров

Рассмотрим пример системы централизованного логирования на
примере Elastic стека (ранее известного как ELK): который включает
в себя 3 осовных компонента:
- ElasticSearch (TSDB и поисковый движок для хранения данных)
- Logstash (для агрегации и трансформации данных)
- Kibana (для визуализации)

Однако для агрегации логов вместо Logstash мы будем
использовать Fluentd, таким образом получая еще одно
популярное сочетание этих инструментов, получившее название EFK

Создал docker-compose-logging.yml
```
version: '3.3'
services:
  fluentd:
    image: ${USERNAME}/fluentd
    ports:
      - "24224:24224"
      - "24224:24224/udp"

  elasticsearch:
    image: elasticsearch:7.5.0
    expose:
      - 9200
    ports:
      - "9200:9200"

  kibana:
    image: kibana:7.5.0
    ports:
      - "5601:5601"
```

Fluentd инструмент, который может использоваться для
отправки, агрегации и преобразования лог-сообщений.
Мы будем использовать Fluentd для агрегации (сбора в одной месте) и
парсинга логов сервисов нашего приложения.

Создал папку logging/fluend и в ней Dockerfile
```
FROM fluent/fluentd:v0.12
RUN gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5
RUN gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0
ADD fluent.conf /fluentd/etc
```

Тамже создал fluent.conf
```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```

Собрал образ с fluentd
```
cd logging/fluentd
docker build -t $USER_NAME/fluentd .
```

#### Структурированные логи

Логи должны иметь заданную (единую) структуру и содержать
необходимую для нормальной эксплуатации данного сервиса
информацию о его работе.

Лог-сообщения также должны иметь понятный для выбранной
системы логирования формат, чтобы избежать ненужной траты
ресурсов на преобразование данных в нужный вид.
Структурированные логи рассмотрим на примере сервиса post.

Поправил версии контейнеров на `logging` в .env файле.

Запустил сервисы
```
docker-compose up -d
```

Вывел логи сервиса post:
```
docker-compose logs -f post

Attaching to reddit_post_1
post_1     | {"addr": "172.20.0.2", "event": "request", "level": "info", "method": "GET", "path": "/healthcheck?", "request_id": null, "response_status": 200, "service": "post", "timestamp": "2019-12-08 21:24:37"}
```

Создал новый пост, вижу в логах:
```
post_1     | {"event": "find_all_posts", "level": "info", "message": "Successfully retrieved all posts from the database", "params": {}, "request_id": "91b02815-491c-464a-a26a-0ba465573fa3", "service": "post", "timestamp": "2019-12-08 21:25:58"}
post_1     | {"addr": "172.20.0.2", "event": "request", "level": "info", "method": "GET", "path": "/posts?", "request_id": "aa6dbf81-c1a6-4604-a781-afc3c8e14445", "response_status": 200, "service": "post", "timestamp": "2019-12-08 21:26:04"}
post_1     | {"event": "post_create", "level": "info", "message": "Successfully created a new post", "params": {"link": "http://123.ru", "title": "123"}, "request_id": "249bcd66-494b-44bc-8b1e-ea0051bab813", "service": "post", "timestamp": "2019-12-08 21:26:04"}
```

Добавил драйвер для fluentd в docker-compose.yml
```
  post:
    ...
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.post
```

Поднял инфраструктуру централизованной системы
логирования и перезапустил сервисы приложения
```
docker-compose -f docker-compose-logging.yml up -d
docker-compose down
docker-compose up -d
```

Kibana - инструмент для визуализации и анализа логов от
компании Elastic.

Зашел в веб-интерфейс кибаны http://34.66.124.51:5601,
увидел ошибку - `Kibana server is not ready yet`

В логах elasticsearch ошибки:
```
docker-compose -f docker-compose-logging.yml logs -f elasticsearch

...
ERROR: [2] bootstrap checks failed
elasticsearch_1  | [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
elasticsearch_1  | [2]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured
...
```

Решение первой проблемы - увеличил `max virtual memory areas` на докер-хосте:
```
docker-machine ssh logging
sudo sysctl -w vm.max_map_count=262144
exit
```

Решение второй проблемы - добавил переменную окружения в запуск `elasticsearch`:
```
elasticsearch:
  ...
  environment:
    - discovery.type=single-node
```

В веб-интерфейсе нажал "Discover" и создал индекс:<br>
Index pattern: fluentd-*<br>
Time Filter field name: @timestamp<br>

Добавил фильтр логов в fluent.conf
```
<filter service.post>
  @type parser
  format json
  key_name log
</filter>
```

Пересобрал образ и перезапустил fluentd
```
cd ../logging/fluentd
docker build -t $USER_NAME/fluentd .
cd ../../docker
docker-compose -f docker-compose-logging.yml up -d fluentd
```

#### Неструктурированные логи

Неструктурированные логи отличаются отсутствием четкой
структуры данных. Также часто бывает, что формат лог-сообщений
не подстроен под систему централизованного логирования, что
существенно увеличивает затраты вычислительных и временных
ресурсов на обработку данных и выделение нужной информации.

На примере сервиса ui мы рассмотрим пример логов с
неудобным форматом сообщений.

Добавил в docker-compose.yml лог-драйвер для ui:
```
  ui:
    ...
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.ui
```

Перезапустил приложение:
```
docker-compose stop ui
docker-compose rm ui
docker-compose up -d
```

В кибане неструктурированный лог выглядит так:
```
I, [2019-12-09T21:28:24.776558 #1]  INFO -- : service=ui | event=show_all_posts | request_id=5e685143-e71f-476c-ad2a-40fb6a876925 | message='Successfully showed the home page with posts' | params: "{}"
```

Добавил в fluent.conf парсинг такого лога с помощью регулярных выражений:
```
<filter service.ui>
  @type parser
  format /\[(?<time>[^\]]*)\]  (?<level>\S+) (?<user>\S+)[\W]*service=(?<service>\S+)[\W]*event=(?<event>\S+)[\W]*(?:path=(?<path>\S+)[\W]*)?request_id=(?<request_id>\S+)[\W]*(?:remote_addr=(?<remote_addr>\S+)[\W]*)?(?:method= (?<method>\S+)[\W]*)?(?:response_status=(?<response_status>\S+)[\W]*)?(?:message='(?<message>[^\']*)[\W]*)?/
  key_name log
</filter>
```

Пересобрал образ и перезапустил контейнер:
```
cd ../logging/fluentd
docker build -t $USER_NAME/fluentd .
cd ../../docker
docker-compose -f docker-compose-logging.yml up -d
```

Созданные регулярки могут иметь ошибки, их сложно менять и
невозможно читать. Для облегчения задачи парсинга вместо
стандартных регулярок можно использовать grok-шаблоны. По-сути
grok’и - это именованные шаблоны регулярных выражений (очень
похоже на функции). Можно использовать готовый regexp, просто
сославшись на него как на функцию docker/fluentd/fluent.conf
```
...
<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>
...
```

Это grok-шаблон, зашитый в плагин для fluentd. В развернутом
виде он выглядит вот так:
```
%{RUBY_LOGGER} [(?<timestamp>(?>\d\d){1,2}-(?:0?[1-9]|1[0-2])-(?:(?:0[1-9])|(?:[12][0-9])|
(?:3[01])|[1-9])[T ](?:2[0123]|[01]?[0-9]):?(?:[0-5][0-9])(?::?(?:(?:[0-5]?[0-9]|60)(?:
[:.,][0-9]+)?))?(?:Z|[+-](?:2[0123]|[01]?[0-9])(?::?(?:[0-5][0-9])))?) #(?<pid>\b(?:[1-9]
[0-9]*)\b)\] *(?<loglevel>(?:DEBUG|FATAL|ERROR|WARN|INFO)) -- +(?<progname>.*?): (?
<message>.*)
```

### Распределенный трейсинг

Добавил zipkin в docker-compose-logging.yml
```
zipkin:
    image: openzipkin/zipkin
    ports:
      - "9411:9411"
```

Добавил для всех сервисов в docker-compose.yml:
```
environment:
  - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
```

Добавил в .env
```
ZIPKIN_ENABLED=true
```

Добавил сети приложения в docker-compose-logging.yml
```
  zipkin:
    ...
    networks:
      - front_net
      - back_net
...
networks:
  back_net:
  front_net:
```

Пересоздал сервисы:
```
docker-compose -f docker-compose-logging.yml -f docker-compose.yml down
docker-compose -f docker-compose-logging.yml -f docker-compose.yml up -d
```

Зашел в веб-интерфейс zipkin http://34.66.124.51:9411
