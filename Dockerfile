FROM sebp/lighttpd

MAINTAINER Tornike Zedginidze <tokozedg@gmail.com>

ADD ./.build/html /var/www/localhost/htdocs

EXPOSE 80
