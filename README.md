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
