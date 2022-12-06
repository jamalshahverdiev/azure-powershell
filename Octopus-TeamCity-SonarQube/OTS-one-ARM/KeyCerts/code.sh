#!/usr/bin/env bash

sudo cp /home/$1/server.crt /opt/bitnami/apache2/conf/server.crt
sudo cp /home/$1/server.key /opt/bitnami/apache2/conf/server.key

sudo cp /opt/bitnami/apache2/conf/bitnami/bitnami.conf .

sudo awk -v block='  ServerName quality.digitalcommerce.volvocars.com
  ServerAlias www.quality.digitalcommerce.volvocars.com
  Redirect permanent / https://quality.digitalcommerce.volvocars.com/' '{ print } /<VirtualHost _default_:80>/ { print block }' bitnami.conf > output.conf

sudo cp output.conf /opt/bitnami/apache2/conf/bitnami/bitnami.conf

sudo /etc/init.d/bitnami restart