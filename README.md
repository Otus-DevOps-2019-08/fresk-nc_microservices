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
