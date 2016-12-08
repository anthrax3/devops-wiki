Devops Toolkit 2.0
##################

.. sidebar:: Meta

    :Optimization: Fine
    :Last Review: Never
    :Importance: High
    :Updated: |today|

.. contents::
    :Depth: 5

...............................................................................

book-ms
*******

Vagrant
=======

:dev: 10.100.199.200

Dockerfile
==========

Runs compiled JAR application.

docker-compose-dev.yml
======================

.. option:: app

  Run application linked to MongoDB container.

.. option:: tests

  Run all pre-deployment test and compile to JAR.

.. option:: testsLocal

  Start db, run functional, unit, front tests and compile to JAR.

.. option:: feTestsLocal

  Run whole application and watch for changes to run tests.

ms-lifecycle
************

Vagrant
=======

:cd: 10.100.198.200
:prod: 10.100.198.201

Pipeline
========

1. Check out the code
2. Run pre-deployment tests
3. Compile and/or package the code
4. Build the container
#. Push the container to the registry
#. Deploy the container to the production server
#. Integrate the container
#. Run post-integration tests
#. Push the tests container to the registry

1. ``git clone https://github.com/vfarcic/books-ms.git``
2. Tests that do not require the service to be deployed.

   .. sourcecode:: sh

     docker build -f Dockerfile.test -t 10.100.198.200:5000/books-ms-tests .
     docker-compose -f docker-compose-dev.yml run --rm tests

3. Generated after tests: ``ll target/scala-2.10/``
4. ``docker build -t 10.100.198.200:5000/books-ms .``
5. ``docker push 10.100.198.200:5000/books-ms``



System Architecture
*******************

Monolithic application was divided into presentation layer, business layer,
data access layer which is relatively good idea for small projects.
As application grows this architecture becomes unmanageable as even simple
feature might require lots of code because of layers.

Service-Oriented Architecture (SOA)
===================================

Four main concepts:

  #. Boundaries are explicit
  #. Services are autonomous
  #. Service share schema and contract but not class
  #. Service compatibility is based on policy

Microservices
=============

Package service date (decentralize) withing container is usually a better
design rather than using centralized database.

Remote process call with microservices introduce more overhead. Consider
splitting application by in a way to keep it organized and reduced remote
calls.


.. image:: images/micro_shared_db.png

On refactoring legacy systems to microservices, database is the most sensible
and high risk park. There is one approach when we have shared database but
schema/table is accessible from single container only, if other container needs
access, it uses API from responsible container.

With back-end being split into microservices and front-end being monolithic,
services we are building do not truly adhere to the idea that each should
provide a full functionality.

Docker
******

Use COPY unless you need additional features that ADD provides.

.. sourcecode:: sh

  DOCKER_OPTS="$DOCKER_OPTS --insecure-registry 10.100.198.200:5000
  -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock

.. sourcecode:: sh

  PORT=$(docker inspect  --format='{{(index (index .NetworkSettings.Ports
  "8080/tcp") 0).HostPort}}' vagrant_app_1)

.. sourcecode:: sh

  # Use remote docker daemon
  export DOCKER_HOST=tcp://prod:2375
  docker ps

docker-compose
**************

Use ``extends`` to override targets and avoid duplications.

``docker-compose scale app=2``

Service Discovery
*****************

etcd
====

.. image:: images/etcd-docker.png

.. sourcecode:: sh

  # Usage example

  etcdctl set myService/ip "1.2.3.4"
  etcdctl ls myService
  etcdctl rm myService/port

  curl http://localhost:2379/v2/keys/myService/newPort \
  -X PUT \
  -d value="4321" | jq '.'

  curl http://localhost:2379/v2/keys/myService/newPort \
  | jq '.'

  curl http://localhost:2379/v2/keys/ | jq '.'

.. sourcecode:: sh

  # Cluster example

  NODE_NAME=serv-disc-0$NODE_NUMBER
  NODE_IP=10.100.197.20$NODE_NUMBER
  NODE_01_ADDRESS=http://10.100.197.201:2380
  NODE_01_NAME=serv-disc-01
  NODE_01="$NODE_01_NAME=$NODE_01_ADDRESS"
  NODE_02_ADDRESS=http://10.100.197.202:2380
  NODE_02_NAME=serv-disc-02
  NODE_01="$NODE_02_NAME=$NODE_02_ADDRESS"
  NODE_03_ADDRESS=http://10.100.197.203:2380
  NODE_03_NAME=serv-disc-03
  NODE_01="$NODE_03_NAME=$NODE_03_ADDRESS"
  CLUSTER_TOKEN=serv-disc-cluster

  etcd -name serv-disc-1 \
  -initial-advertise-peer-urls http://$NODE_IP:2380 \
  -listen-peer-urls http://$NODE_IP:2380 \
  -listen-client-urls \
  http://$NODE_IP:2379,http://127.0.0.1:2379 \
  -advertise-client-urls http://$NODE_IP:2379 \
  -initial-cluster-token $CLUSTER_TOKEN \
  -initial-cluster \
  $NODE_01,$NODE_02,$NODE_03 \
  -initial-cluster-state new

registrator
-----------

Detects container run/termination and updates service discovery. Supports etcd,
Consul, SkyDNS.

.. sourcecode:: sh

  docker run -d --name registrator \
    -v /var/run/docker.sock:/tmp/docker.sock \
    -h serv-disc-01 \
    gliderlabs/registrator \
    -ip 10.100.194.201 etcd://10.100.194.201:2379

  # Set friendly service name for registrator per container
  docker run -d --name nginx \
    --env SERVICE_NAME=nginx \
    --env SERVICE_ID=nginx \
    -p 1234:80 \
    nginx

confd
-----

Build application configuration file from template and service discovery
key/values.

Daemon polls service discovery and updates config files.

.. sourcecode:: sh

   # One time
   confd -onetime -backend etcd -node 10.100.197.202:2379

Sample config stanza::

  # /etc/confd/conf.d/example.toml
  [template]
  src = "nginx.conf.tmpl"
  dest = "/tmp/nginx.conf"
  keys = [
     "/nginx-80/nginx"
  ]

Sample template file. Uses Golang text templates::

  # /etc/confd/templates/example.conf.toml
  The address is {{getv "/nginx-80/nginx"}}


Consul
======

.. image:: images/consul-docker.png

Implements service discovery system embedded.
Clients only need to register services and perform discovery using the DNS or
HTTP interface.
Includes ability to discover deployed services and nodes they reside on and
implement health checks via TCP, HTTP, custom scripts, TTL, docker commands.

Consul uses *gossip*: one node should run Consul in the server node and the
rest should join at least one node so that Consul can gossip that information
to the whole cluster.

.. sourcecode:: sh

 consul agent \
   -server \
   -bootstrap-expect 1 \ #expect 1 server instance
   -ui-dir /data/consul/ui \
   -data-dir /data/consul/data \
   -config-dir /data/consul/config \
   -node=cd \
   -bind=10.100.198.200 \
   -client=0.0.0.0 \ # clients from any source
   >/tmp/consul.log &

.. sourcecode:: sh

  curl -X PUT -d 'this is a test'  http://localhost:8500/v1/kv/msg1
  curl -X PUT -d 'this is another test' \
   http://localhost:8500/v1/kv/messages/msg2
  curl -X PUT -d 'this is a test with flags' \
   http://localhost:8500/v1/kv/messages/msg3?flags=1234
  # Flags is integers and used to store version or any other info with the key.

  curl http://localhost:8500/v1/kv/?recurse | jq '.'
  curl http://localhost:8500/v1/kv/msg1?raw # only value
  curl -X DELETE http://localhost:8500/v1/kv/messages/msg2<Paste>

.. sourcecode:: sh

  # Join agent to server
  consul agent \
   -ui-dir /data/consul/ui \
   -data-dir /data/consul/data \
   -config-dir /data/consul/config \
   -node=serv-disc-02 \
   -bind=10.100.197.202 \
   -client=0.0.0.0 \
   >/tmp/consul.log &

  consul join 10.100.198.200

  curl serv-disc-01:8500/v1/catalog/nodes | jq '.'

registrator
-----------

Run registrator with consulkv protocol.

.. sourcecode:: sh

  docker run -d --name registrator-consul-kv \
   -v /var/run/docker.sock:/tmp/docker.sock \
   -h serv-disc-01 \
   gliderlabs/registrator \
   -ip 10.100.194.201 consulkv://10.100.194.201:8500/services

  curl http://serv-disc-01:8500/v1/kv/services/nginx-80/nginx?raw

With consul protocol we can additional info.

.. sourcecode:: sh

  docker run -d --name registrator-consul \
  -v /var/run/docker.sock:/tmp/docker.sock \
  -h serv-disc-01 \
  gliderlabs/registrator \
  -ip 10.100.194.201 consul://10.100.194.201:8500

  docker run -d --name nginx2 \
    --env "SERVICE_ID=nginx2" \
    --env "SERVICE_NAME=nginx" \
    --env "SERVICE_TAGS=balancer,proxy,www" \
    -p 1111:80 \
    nginx

consul-template
----------------

.. sourcecode:: sh

  #/tmp/nginx.ctmpl
  {{range service "nginx"}}
  The address is {{.Address}}:{{.Port}}
  {{end}}

  consul-template \
   -consul serv-disc-01:8500 \
   -template "/tmp/nginx.ctmpl:/tmp/nginx.conf" \
   -once


  curl http://serv-disc-01:8500/v1/catalog/service/nginx-80 | jq '.'

  [
    {
      "ModifyIndex": 96,
      "CreateIndex": 96,
      "Node": "serv-disc-01",
      "Address": "10.100.194.201",
      "ServiceID": "nginx2",
      "ServiceName": "nginx-80",
      "ServiceTags": [
        "balancer",
        "proxy",
        "www"
      ],
      "ServiceAddress": "10.100.194.201",
      "ServicePort": 1111,
      "ServiceEnableTagOverride": false
    }
  ]

Proxy
*****

.. image:: images/proxy-docker.png
   :width: 300pt

nginx
=====

::

  # Reloads config
  docker kill -s HUP nginx

::

  # Sample Concul template
  upstream books-ms {
      {{range service "books-ms" "any"}}
      server {{.Address}}:{{.Port}};
      {{end}}
  }

  upstream books-ms {
      server 10.100.193.200:32768;
      server 10.100.193.200:32769;
  }


  location /api/v1/books {
    proxy_pass http://books-ms/api/v1/books;
    proxy_next_upstream error timeout invalid_header http_500;
  }

haproxy
=======

HAProxy can drop traffic during reloads.
Official container doesn't support config reload.
Logs aren't sent to stdout, we can use syslog for HAProxy logs withing
container.

::

  # Define a frontend called books-ms-fe, bind it to the port 80 and, whenever
  # the request part starts with /api/v1/books, use the backend called
  # books-ms-be

  frontend books-ms-fe # location in nginx
    bind *:80
    option http-server-close
    acl url_books-ms path_beg /api/v1/books
    use_backend books-ms-be if url_books-ms
  backend books-ms-be # upstream in nginx
    server books-ms-1 10.100.193.200:$PORT check

  # Sample Consul template

  backend books-ms-be
      {{range service "books-ms" "any"}}
      server {{.Node}}_{{.Port}} {{.Address}}:{{.Port}} check
      {{end}}
