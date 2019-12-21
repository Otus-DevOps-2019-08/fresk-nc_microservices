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

## Homework 19. Введение в Kubernetes

Создал директорию kubernetes в корне проекта. Внутри нее создал директорию reddit.
Создал 4 манифеста.

post-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: post-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: post
  template:
    metadata:
      name: post
      labels:
        app: post
    spec:
      containers:
        - image: fresk/post
          name: post
```

ui-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ui-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ui
  template:
    metadata:
      name: ui
      labels:
        app: ui
    spec:
      containers:
        - image: fresk/ui
          name: ui
```

comment-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: comment-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: comment
  template:
    metadata:
      name: comment
      labels:
        app: comment
    spec:
      containers:
        - image: fresk/comment
          name: comment
```

mongo-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: mongo
    spec:
      containers:
        - image: mongo:3.2
          name: mongo
```

### Kubernetes The Hard Way

https://github.com/kelseyhightower/kubernetes-the-hard-way

Создал директорию kubernetes/the_hard_way

Установил дефолтный регион и дефолтную зону для GCP:
```
gcloud config set compute/region us-west1
gcloud config set compute/zone us-west1-c
```

Установил cfssl и cfssljson
```
curl -o cfssl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/darwin/cfssl
curl -o cfssljson https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/darwin/cfssljson
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/
```

Установил kubectl
```
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/darwin/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

Создал custom VPC network и подсеть
```
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
```

Создал фаервол правила
```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
```

Создал статичый IP-адресс для внешнего балансера
```
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)
```

Создал три виртуалки для контроллеров
```
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
```

Создал три виртуалки для воркеров
```
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
```

Создал ssh-ключи
```
gcloud compute ssh controller-0
```
> Ключи автоматически сгенерировались и загрузились в GCP

Сгенерировал CA конфигурационный файл, сертификат и приватный ключ
```
cd kubernetes/the_hard_way

{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}
```

Сгенерировал админский клиентский сертификат и приватный ключ
```
{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

}
```

Сгенерировал сертификат и приватный ключ для каждого воркера
```
for instance in worker-0 worker-1 worker-2; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done
```

Сгенерировал сертификат и приватный ключ для kube-contoller-manager
```
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}
```

Сгенерировал сертификат и приватный ключ для kube-proxy
```
{

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}
```

Сгенерировал сертификат и приватный ключ для kube-scheduler
```
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}
```

Сгенерировал сертификат и приватный ключ для Kubernetes API Server
```
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
```

Сгенерировал сертификат и приватный ключ для Service Account
```
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}
```

Доставил сертификаты и ключи на воркеры
```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done
```

Доставил сертификаты и ключи на контроллеры
```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done
```

Сохранил в переменную адрес балансера
```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

Сгенерировал kubeconfig для каждого воркера
```
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
```

Сгенерировал kubeconfig для kube-proxy
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
```

Сгенерировал kubeconfig для контроллера
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}
```

Сгенерировал kubeconfig для kube-scheduler
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}
```

Сгенерировал kubeconfig для юзера admin
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}
```

Доставил конфиги на виртуалки
```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done

for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

Сгенерировал ключ
```
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

Создал encryption-config.yaml
```
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

Скопировал encryption-config.yaml на каждый контроллер
```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
```

Установил tmux
```
brew install tmux
```

Далее с помощью tmux выполнил действия сразу на трех контроллерах

Установил etcd
```
{
  wget -q --show-progress --https-only --timestamping \
    "https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"
  tar -xvf etcd-v3.4.0-linux-amd64.tar.gz
  sudo mv etcd-v3.4.0-linux-amd64/etcd* /usr/local/bin/
}
```

Сконфигурировал etcd
```
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
}
```

Сохранил в переменную внутренний IP
```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Сохранил в переменную имя хоста
```
ETCD_NAME=$(hostname -s)
```

Создал файл etcd.service
```
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Запустил etcd сервер
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
```

Создал папку
```
sudo mkdir -p /etc/kubernetes/config
```

Скачал и установил бинарники кубернетиса
```
{
  wget -q --show-progress --https-only --timestamping \
    "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-apiserver" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-controller-manager" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-scheduler" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl"
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}
```

Сконфигурировал Kubernetes API Server
```
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
}
```

Сохранил в переменную внутренний IP
```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Создал kube-apiserver.service
```
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Переместил kube-controller-manager.kubeconfig
```
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Создал kube-controller-manager.service
```
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Переместил kube-scheduler.kubeconfig
```
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Создал kube-scheduler.yaml
```
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

Создал kube-scheduler.service
```
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Запустил kube-apiserver kube-controller-manager kube-scheduler
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}
```

Так как GCP балансер поддерживает только HTTP health checks,
а kube-apiserver HTTPS, поставил nginx для проксирования HTTP -> HTTPS
```
sudo apt-get update
sudo apt-get install -y nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

{
  sudo mv kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

  sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
}

sudo systemctl restart nginx
sudo systemctl enable nginx
```

Следующие команды запускал только на controller-0

```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

Следующие команды запускал локально

Создал внешний балансер
```
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  gcloud compute http-health-checks create kubernetes \
    --description "Kubernetes Health Check" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"

  gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
    --network kubernetes-the-hard-way \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

  gcloud compute target-pools create kubernetes-target-pool \
    --http-health-check kubernetes

  gcloud compute target-pools add-instances kubernetes-target-pool \
   --instances controller-0,controller-1,controller-2

  gcloud compute forwarding-rules create kubernetes-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region $(gcloud config get-value compute/region) \
    --target-pool kubernetes-target-pool
}
```

Следующие команды запускал параллельно на трех воркерах

Установил зависимости
```
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
}
```

Проверил, что swap выключен
```
sudo swapon --show
```

Скачал бинарники воркеров
```
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet
```

Создал директории
```
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Установил бинарники
```
{
  mkdir containerd
  tar -xvf crictl-v1.15.0-linux-amd64.tar.gz
  tar -xvf containerd-1.2.9.linux-amd64.tar.gz -C containerd
  sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
  sudo mv runc.amd64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc 
  sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  sudo mv containerd/bin/* /bin/
}
```

Сохранил в переменную pod CIDR диапазон
```
POD_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)
```

Создал конфигурацию для бриджа
```
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

Создал конфигурацию для loopback
```
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF
```

Создал конфигурацию дял containerd
```
sudo mkdir -p /etc/containerd/

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF
```

Создал containerd.service
```
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

Сконфигурировал kubelet
```
{
  sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.pem /var/lib/kubernetes/
}

cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
```

Создал kubelet.service
```
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Сконфигурировал kube-proxy
```
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
```

Создал kube-proxy.service
```
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Запустил containerd kubelet kube-proxy
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
```

Следующие команды запускал локально

Сгенерировал kubeconfig для аутентификации админа
```
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```

Создал роуты для каждого воркера
```
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
```

Настроил DNS Cluster Add-on
```
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml
```

Выполнил smoke-test https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/13-smoke-test.md

Проверил запуск post пода
```
kubectl apply -f ../reddit/post-deployment.yml
deployment.apps/post-deployment created

kubectl get pods -l app=post
NAME                              READY   STATUS    RESTARTS   AGE
post-deployment-c5d844c8c-58wtq   1/1     Running   0          97s
```

Проверил запуск ui пода
```
kubectl apply -f ../reddit/ui-deployment.yml
deployment.apps/ui-deployment created

kubectl get pods -l app=ui
NAME                             READY   STATUS              RESTARTS   AGE
ui-deployment-58964dc547-k2t8t   0/1     ContainerCreating   0          20s
```

Проверил запуск comment пода
```
kubectl apply -f ../reddit/comment-deployment.yml
deployment.apps/comment-deployment created

kubectl get pods -l app=comment
NAME                                  READY   STATUS    RESTARTS   AGE
comment-deployment-5786c6d84f-jcfkd   1/1     Running   0          42s
```

Проверил запуск mongo пода
```
kubectl apply -f ../reddit/mongo-deployment.yml
deployment.apps/mongo-deployment created

kubectl get pods -l app=mongo
NAME                                READY   STATUS    RESTARTS   AGE
mongo-deployment-86d49445c4-8snqr   1/1     Running   0          39s
```

Удалил все ранее созданные GCP ресурсы
```
gcloud -q compute instances delete \
  controller-0 controller-1 controller-2 \
  worker-0 worker-1 worker-2 \
  --zone $(gcloud config get-value compute/zone)
  
{
  gcloud -q compute forwarding-rules delete kubernetes-forwarding-rule \
    --region $(gcloud config get-value compute/region)

  gcloud -q compute target-pools delete kubernetes-target-pool

  gcloud -q compute http-health-checks delete kubernetes

  gcloud -q compute addresses delete kubernetes-the-hard-way
}

gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-nginx-service \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-check
  
{
  gcloud -q compute routes delete \
    kubernetes-route-10-200-0-0-24 \
    kubernetes-route-10-200-1-0-24 \
    kubernetes-route-10-200-2-0-24

  gcloud -q compute networks subnets delete kubernetes

  gcloud -q compute networks delete kubernetes-the-hard-way
}
```

## Homework 20. Kubernetes. Запуск кластера и приложения. Модель безопасности.

Установил kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-maco

Установил virtualbox https://www.virtualbox.org/wiki/Downloads

Установил minicube https://kubernetes.io/docs/tasks/tools/install-minikube/

Запустил minicube
```
minicube start

kubectl get nodes

NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    master   10s   v1.17.0
```

Конфигурация kubectl - это контекст.

Контекст - это комбинация: 
- **cluster** - API-сервер
- **user** - пользователь для подключения к кластеру
- **namespace** - область видимости (не обязательно, поумолчанию default) 

Информацию о контекстах kubectl сохраняет в файле `~/.kube/config`

Кластер (cluster) - это:
- **server** - адрес kubernetes API-сервера
- **certificate-authority** - корневой сертификат (которым
  подписан SSL-сертификат самого сервера), чтобы
  убедиться, что нас не обманывают и перед нами тот
  самый сервер
- **name** для идентификации в конфиге

Пользователь (user) - это: 
- Данные для аутентификации (зависит от того, как настроен сервер). Это могут быть 
username + password (Basic Auth) или client key + client certificate или token или 
auth-provider config (например GCP) 
- name (Имя) для идентификации в конфиге

Обычно порядок конфигурирования kubectl следующий:
1. Создать cluster:
```
kubectl config set-cluster … cluster_name
```
2. Создать данные пользователя (credentials)
```
kubectl config set-credentials … user_name
```
3. Создать контекст
```
kubectl config set-context context_name \
   --cluster=cluster_name \
   --user=user_name
```
4. Использовать контекст
```
kubectl config use-context context_name
```

Текущий контекст можно увидеть так:
```
kubectl config current-context
```

Список всех контекстов можно увидеть так:
```
kubectl config get-contexts
```

### Запуск приложения

#### ui

Обновил kubernetes/reddit/ui-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: ui
  template:
    metadata:
      name: ui-pod
      labels:
        app: reddit
        component: ui
    spec:
      containers:
        - image: fresk/ui
          name: ui
```

Запустил в Minikube ui
```
cd kubernetes/reddit
kubectl apply -f ui-deployment.yml 

deployment "ui" created
```

```
kubectl get deployment

NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     0/3     3            0           59s
```

> `kubectl apply -f <filename>` может принимать не только
отдельный файл, но и папку с ними. Например `kubectl apply -f ./kubernetes/reddit` 

Пока что мы не можем использовать наше приложение полностью,
потому что никак не настроена сеть для общения с ним.
Но kubectl умеет пробрасывать сетевые порты POD-ов на локальную
машину.

Нашел с помошью selector, POD-ы приложения:
```
kubectl get pods --selector component=ui

NAME                  READY   STATUS    RESTARTS   AGE
ui-57bdb474bb-5knx7   1/1     Running   0          3m5s
ui-57bdb474bb-bzk9r   1/1     Running   0          3m5s
ui-57bdb474bb-npnzm   1/1     Running   0          3m5s
```

Пробросил порт
```
kubectl port-forward ui-57bdb474bb-5knx7 8080:9292
```

> 8080:9292 - local-port:pod-port

Зашел в браузере на http://localhost:8080/, увидел интерфейс.

#### comment

Обновил kubernetes/reddit/comment-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: comment
  labels:
    app: reddit
    component: comment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: comment
  template:
    metadata:
      name: comment
      labels:
        app: reddit
        component: comment
    spec:
      containers:
        - image: fresk/comment
          name: comment
```

Запустил в Minikube comment
```
kubectl apply -f comment-deployment.yml

deployment.apps/comment created
```

```
kubectl get deployment

NAME      READY   UP-TO-DATE   AVAILABLE   AGE
comment   0/3     3            0           50s
ui        3/3     3            3           10m
```

Нашел с помошью selector, POD-ы приложения:
```
kubectl get pods --selector component=comment

NAME                       READY   STATUS              RESTARTS   AGE
comment-7767b5ccf4-9pshg   0/1     ContainerCreating   0          99s
comment-7767b5ccf4-srk4z   0/1     ContainerCreating   0          99s
comment-7767b5ccf4-tttg9   0/1     ContainerCreating   0          99s
```

Пробросил порт
```
kubectl port-forward comment-7767b5ccf4-9pshg 8080:9292
```

Зашел в браузере на http://localhost:8080/healthcheck, увидел:
```
{"status":0,"dependent_services":{"commentdb":0},"version":"0.0.3"}
```

#### post

Обновил kubernetes/reddit/post-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: post
  template:
    metadata:
      name: post
      labels:
        app: reddit
        component: post
    spec:
      containers:
        - image: fresk/post
          name: post
```

Запустил в Minikube post
```
kubectl apply -f post-deployment.yml

deployment.apps/post created
```

```
kubectl get deployment

NAME      READY   UP-TO-DATE   AVAILABLE   AGE
comment   3/3     3            3           4m3s
post      2/3     3            2           18s
ui        3/3     3            3           14m
```

Нашел с помошью selector, POD-ы приложения:
```
kubectl get pods --selector component=post

NAME                    READY   STATUS    RESTARTS   AGE
post-69656d7dbd-fcgtq   1/1     Running   0          31s
post-69656d7dbd-gt4sm   1/1     Running   0          32s
post-69656d7dbd-thckg   1/1     Running   0          32s
```

Пробросил порт
```
kubectl port-forward post-69656d7dbd-fcgtq 8080:5000
```

Зашел в браузере на http://localhost:8080/healthcheck, увидел:
```
{"status": 0, "dependent_services": {"postdb": 0}, "version": "0.0.2"}
```

#### mongodb

Обновил kubernetes/reddit/mongo-deployment.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
    spec:
      containers:
        - image: mongo:3.2
          name: mongo
```

Также примонтировал стандартный Volume для хранения данных вне контейнера
```
...
containers:
  - image: mongo:3.2
    name: mongo
    volumeMounts:
      - name: mongo-persistent-storage
        mountPath: /data/db
volumes:
  - name: mongo-persistent-storage
    emptyDir: {}
```

Это точка монтирования в контейнере (не в POD-е)
```
volumeMounts:
  - name: mongo-persistent-storage
    mountPath: /data/db
```

Это ассоциированные с POD-ом Volume-ы
```
volumes:
  - name: mongo-persistent-storage
    emptyDir: {}
```

Запустил в Minicube mongo
```
kubectl apply -f mongo-deployment.yml
```

#### Services

В текущем состоянии приложение не будет
работать, так его компоненты ещё не знают как
найти друг друга.

Для связи компонент между собой и с внешним
миром используется объект Service - абстракция,
которая определяет набор POD-ов (Endpoints) и
способ доступа к ним.

Для связи ui с post и comment нужно создать им по
объекту Service.

comment-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: comment
  labels:
    app: reddit
    component: comment
spec:
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: comment
```

Запустил
```
kubectl apply -f comment-service.yml
```

Когда объект service будет создан:
1. В DNS появится запись для comment
2. При обращении на адрес post:9292
изнутри любого из POD-ов текущего
namespace нас переправит на 9292-ный
порт одного из POD-ов приложения post,
выбранных по label-ам.

```
kubectl describe service comment | grep Endpoints

Endpoints: 172.17.0.7:9292,172.17.0.8:9292,172.17.0.9:9292
```

По аналогии создал post-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  ports:
    - port: 5000
      protocol: TCP
      targetPort: 5000
  selector:
    app: reddit
    component: post
```

Запустил
```
kubectl apply -f post-service.yml
```

```
kubectl describe service post | grep Endpoints

Endpoints: 172.17.0.10:5000,172.17.0.11:5000,172.17.0.12:5000
```

По аналогии mongo-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  labels:
    app: reddit
    component: mongo
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
```

Запустил
```
kubectl apply -f mongo-service.yml
```

Пробросил порт для ui
```
kubectl port-forward ui-57bdb474bb-5knx7 9292:9292
```

Приложение не открывается, так  ищет совсем другой адрес:
comment_db, а не mongodb. Аналогично и сервис comment ищет post_db.

Эти адреса заданы в их Dockerfile-ах в виде переменных
окружения:
```
post/Dockerfile
…
ENV POST_DATABASE_HOST=post_db

comment/Dockerfile
…
ENV COMMENT_DATABASE_HOST=comment_db
```

В Docker Swarm проблема доступа к одному
ресурсу под разными именами решалась с
помощью сетевых алиасов.

В Kubernetes такого функционала нет.
Эту проблему можем решить с помощью тех же Service-ов. 

Создал comment-mongodb-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: comment-db
  labels:
    app: reddit
    component: mongo
    comment-db: "true"
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
    comment-db: "true"
```

В comment-deployment.yml добавил переменную окружения
```
containers:
- image: fresk/comment
  name: comment
  env:
    - name: COMMENT_DATABASE_HOST
      value: comment-db
```

Создал post-mongodb-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: post-db
  labels:
    app: reddit
    component: mongo
    post-db: "true"
spec:
  ports:
    - port: 27017
      protocol: TCP
      targetPort: 27017
  selector:
    app: reddit
    component: mongo
    post-db: "true"
```

В post-deployment.yml добавил переменную окружения
```
containers:
- image: fresk/post
  name: post
  env:
    - name: POST_DATABASE_HOST
      value: post-db
```

Добавил лейблы в mongo-deployment.yml
```
...
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    comment-db: "true"
    post-db: "true"
...
template:
  metadata:
    name: mongo
    labels:
      app: reddit
      component: mongo
      comment-db: "true"
      post-db: "true"
```

Применил изменения
```
kubectl apply -f .
```

Пробросил порт для ui
```
kubectl port-forward ui-57bdb474bb-5knx7 9292:9292
```

Интерфейс открылся

Удалил объект mongo-service.yml
```
kubectl delete -f mongo-service.yml
```

Нам нужно как-то обеспечить доступ к ui-сервису снаружи.
Для этого нам понадобится Service для UI-компоненты.

Создал ui-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: NodePort
  ports:  
    - port: 9292
      protocol: TCP
      targetPort: 9292
  selector:
    app: reddit
    component: ui
```

```
kubectl apply -f ui-service.yml
```

Главное отличие - тип сервиса NodePort.

По-умолчанию все сервисы имеют тип ClusterIP - это значит, что сервис
распологается на внутреннем диапазоне IP-адресов кластера. Снаружи до него
нет доступа.

Тип NodePort - на каждой ноде кластера открывает порт из диапазона
30000-32767 и переправляет трафик с этого порта на тот, который указан в
targetPort Pod (похоже на стандартный expose в docker)

Т.е. в описании service 
- NodePort - для доступа снаружи кластера
- port - для доступа к сервису изнутри кластера

Minikube может выдавать web-странцы с сервисами
которые были помечены типом NodePort
```
minikube service ui
```

Список сервисов
```
minikube service list

|-------------|------------|---------------------------|-----|
|  NAMESPACE  |    NAME    |        TARGET PORT        | URL |
|-------------|------------|---------------------------|-----|
| default     | comment    | No node port              |
| default     | comment-db | No node port              |
| default     | kubernetes | No node port              |
| default     | post       | No node port              |
| default     | post-db    | No node port              |
| default     | ui         | http://192.168.64.2:30599 |
| kube-system | kube-dns   | No node port              |
|-------------|------------|---------------------------|-----|
```

Minikube также имеет в комплекте несколько стандартных аддонов
(расширений) для Kubernetes (kube-dns, dashboard, monitoring,…).
Каждое расширение - это такие же PODы и сервисы, какие
создавались нами, только они еще общаются с API самого Kubernetes

Получить список расширений:
```
minikube addons list
 
- addon-manager: enabled
- dashboard: disabled
- default-storageclass: enabled
- efk: disabled
- freshpod: disabled
- gvisor: disabled
- helm-tiller: disabled
- ingress: disabled
- ingress-dns: disabled
- logviewer: disabled
- metrics-server: disabled
- nvidia-driver-installer: disabled
- nvidia-gpu-device-plugin: disabled
- registry: disabled
- registry-creds: disabled
- storage-provisioner: enabled
- storage-provisioner-gluster: disabled
```

Интересный аддон - dashboard. Это UI для работы с
kubernetes. По умолчанию в новых версиях он включен.
Как и многие kubernetes add-on'ы, dashboard запускается в
виде pod'а.

Если мы посмотрим на запущенные pod'ы с помощью
команды kubectl get pods, то обнаружим только наше
приложение.

Потому что поды и сервисы для dashboard-а были запущены
в namespace (пространстве имен) kube-system.
Мы же запросили пространство имен default.

Namespace - это, по сути, виртуальный кластер Kubernetes
внутри самого Kubernetes. Внутри каждого такого кластера
находятся свои объекты (POD-ы, Service-ы, Deployment-ы и
т.д.), кроме объектов, общих на все namespace-ы (nodes,
ClusterRoles, PersistentVolumes)

В разных namespace-ах могут находится объекты с
одинаковым именем, но в рамках одного namespace имена
объектов должны быть уникальны.

При старте Kubernetes кластер уже имеет 3 namespace:
- default - для объектов для которых не определен другой
  Namespace (в нем мы работали все это время)
- kube-system - для объектов созданных Kubernetes’ом и
  для управления им
- kube-public - для объектов к которым нужен доступ из
  любой точки кластера

Для того, чтобы выбрать конкретное пространство имен, нужно указать
флаг -n <namespace> или --namespace <namespace> при запуске kubectl

В самом Dashboard можно:
- отслеживать состояние кластера и рабочих нагрузок в нем
- создавать новые объекты (загружать YAML-файлы)
- Удалять и изменять объекты (кол-во реплик, yaml-файлы)
- отслеживать логи в Pod-ах
- при включении Heapster-аддона смотреть нагрузку на Podах
- и т.д.

Отделим среду для разработки приложения от всего остального кластера.
Для этого создадим свой Namespace dev

Создал dev-namespace.yml
```
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```
kubectl apply -f dev-namespace.yml
```

Запустил приложение в dev неймспейсе
```
kubectl apply -n dev -f .
```

Добавил инфу об окружении внутрь контейнера UI
```
...
spec:
  containers:
    - image: fresk/ui
      name: ui
      env:
        - name: ENV
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

```
kubectl apply -f ui-deployment.yml -n dev
```

Остановил minikube
```
minikube stop
```

### Kubernetes в GCP

Создал кластер

Зашел в GCP -> Kubernetes Engine -> Create cluster

- Тип машины - небольшая машина (1,7 ГБ) (для экономии ресурсов)
- Размер - 2
- Размер загрузочного диска - 20 ГБ (для экономии)

Подключился к GKE для запуска приложения.
```
gcloud container clusters get-credentials standard-cluster-1 --zone us-central1-a --project docker-258014
```

Проверил текущий контекст
```
kubectl config current-context

gke_docker-258014_us-central1-a_standard-cluster-1
```

Создал dev неймспейс
```
kubectl apply -f dev-namespace.yml
```

Задеплоил все компоненты
```
kubectl apply -f . -n dev
```

Добавил firewall rule
```
Name: kubernetes-reddit-default
Target tags: gke-standard-cluster-1-21728bdb-node
IP ranges: 0.0.0.0/0
Protocols and ports: tcp:30000-32767
```

Нашел внешние адреса нод
```
kubectl get nodes -o wide

NAME                                                STATUS   ROLES    AGE     VERSION           INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-standard-cluster-1-default-pool-8c121e0a-2h90   Ready    <none>   7m26s   v1.13.11-gke.14   10.128.0.4    35.193.3.142    Container-Optimized OS from Google   4.14.138+        docker://18.9.7
gke-standard-cluster-1-default-pool-8c121e0a-l4th   Ready    <none>   7m26s   v1.13.11-gke.14   10.128.0.3    35.188.211.15   Container-Optimized OS from Google   4.14.138+        docker://18.9.7
```

Нашел порт ui
```
kubectl describe service ui -n dev | grep NodePort
Type:                     NodePort
NodePort:                 <unset>  31597/TCP
```

Зашел в браузере http://35.193.3.142:31597, увидел интерфейс reddit

Зашел в настройки кластера и включил Kubernetes Dashboard

```
kubectl proxy

Starting to serve on 127.0.0.1:8001
```

Зашел по адресу http://localhost:8001/ui и увидел какой-то json. Проделал
шаги из [официальной документации](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/), 
после чего получилось увидеть интерфейс дашборда. 


