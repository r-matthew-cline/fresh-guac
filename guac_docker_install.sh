#!/bin/bash

##############################################################################
##
## guac_docker_install.sh
##
## @author: Matthew Cline
## @version: 20190323
##
## Desctiption: Initialize docker containers for guacd, guacamole, and 
## mysql. Configures the mysql database with the default guacamole
## configuration and sets the containers to restart always.
##
##############################################################################


### Get MYSQL Information ###
read -p 'MYSQL Data Path: ' mysql_data
read -sp 'MYSQL Root Password: ' mysql_root_password
read -sp 'Confirm MYSQL Root Password: ' mysql_root_password2
if [ "$mysql_root_password" != "$mysql_root_password2" ]
then
	echo 'Passwords do not match...'
	exit 1
fi
read -p 'Guacamole Database Name: ' guac_db
read -p 'Guacamole DB User: ' guac_db_user
read -sp 'Guacamold DB User Password: ' guac_db_user_password
read -sp 'Confirm Guacamold DB User Password: ' guac_db_user_password2
if [ "$guac_db_user_password" != "$guac_db_user_password" ]
then
	echo 'Passwords do not match...'
	exit 1
fi
mysql_script=$(readlink -f -- ./initdb.sql)
read -p 'External Port: ' external_port

### Start the guacd server ###
echo 'Starting guacd docker image...'
docker run --name guacd --restart unless-stopped -d guacamole/guacd

### Start and configure the mysql container ###
echo 'Starting mysql docker image...'
docker run --name guac_mysql --restart unless-stopped \
	-e MYSQL_ROOT_PASSWORD=$mysql_root_password \
	-e MYSQL_USER=$guac_db_user \
	-e MYSQL_PASSWORD=$guac_db_user_password \
	-e MYSQL_DATABASE=$guac_db \
	-v $mysql_data:/var/lib/mysql \
	-v $mysql_script:/docker-entrypoint-initdb.d/initdb.sql \
	-d mysql:5.7

### Start the guacamole web app ###
echo 'Starting the guacamole web application..."'
docker run --name guacamole --restart unless-stopped\
	--link guacd:guacd \
	--link guac_mysql:mysql \
	-e MYSQL_DATABASE=$guac_db \
	-e MYSQL_USER=$guac_db_user \
	-e MYSQL_PASSWORD=$guac_db_user_password \
	-p $external_port:8080 -d guacamole/guacamole

