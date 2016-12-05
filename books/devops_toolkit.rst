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
======

Use COPY unless you need additional features that ADD provides.

::

  DOCKER_OPTS="$DOCKER_OPTS --insecure-registry 10.100.198.200:5000
  -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock

::

  PORT=$(docker inspect  --format='{{(index (index .NetworkSettings.Ports
  "8080/tcp") 0).HostPort}}' vagrant_app_1)

docker-compose
==============

Use ``extends`` to override targets and avoid duplications.

Run docker-compose on remote docker daemon::

  export DOCKER_HOST=tcp://prod:2375
  docker-compose up -d app

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

   .. sourcecode:: shell

     docker build -f Dockerfile.test -t 10.100.198.200:5000/books-ms-tests .
     docker-compose -f docker-compose-dev.yml run --rm tests
3. Generated after tests: ``ll target/scala-2.10/``
4. ``docker build -t 10.100.198.200:5000/books-ms .``
5. ``docker push 10.100.198.200:5000/books-ms``
