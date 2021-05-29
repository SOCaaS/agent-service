# dockerfile used to setup agentservice similar to start.sh (Not updated to implement agentServiceDaemon)
FROM base/ubuntu-supervisor:latest

ARG INTERFACE
ARG URL
ARG HOST_IP
ARG LOGSTASH_PORT
ARG LOGSTASH_URI
ARG DOCKER_URL

LABEL type="agent-service"

# update, upgrade and install dependencies
RUN apt update

RUN apt upgrade -y

RUN apt-get update && apt-get install -y gnupg2

RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

RUN apt install -y apt-transport-https

RUN echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

# install and configure filebeat to ship logs and data from suricata and tshark
RUN apt update

RUN apt install -y filebeat

ADD filebeat.yml /etc/filebeat/filebeat.yml

RUN sed -i "s/{{ LOGSTASH_URI }}/$LOGSTASH_URI/g" /etc/filebeat/filebeat.yml

RUN sed -i "s/{{ LOGSTASH_PORT }}/$LOGSTASH_PORT/g" /etc/filebeat/filebeat.yml

# installing tshark
# tshark will be used to monitor and capture data from the network
RUN apt install -y tshark

RUN mkdir /tshark

# install and configure suricata
# Suricata will be used as an IDS with default rule of detecting DOS
RUN apt update

RUN apt-get install software-properties-common -y

RUN add-apt-repository ppa:oisf/suricata-stable -y

RUN apt update && apt upgrade -y

RUN apt install suricata suricata-dbg -y

ADD detect-dos.rules /etc/suricata/rules

ADD suricata.yaml /etc/suricata

RUN sed -i "s/{{ HOST_IP }}/$HOST_IP/g" /etc/suricata/suricata.yaml

RUN sed -i "s/{{ INTERFACE }}/$INTERFACE/g" /etc/suricata/suricata.yaml

RUN head -n 20 /etc/suricata/suricata.yaml

RUN suricata-update

# RUN filebeat modules enable suricata

# installing mysql, wordpress and apache2 to simulate a blog website being under attack.

RUN apt update

RUN apt install wordpress -y

RUN apt install apache2 -y

RUN apt install mysql-server -y

ADD config/wordpress.conf /etc/apache2/sites-available

RUN a2ensite wordpress

RUN a2enmod rewrite

ADD config/config.php /etc/wordpress/config.php

RUN cp /etc/wordpress/config.php /etc/wordpress/config-$URL.php

RUN mv /etc/wordpress/config.php /etc/wordpress/config-$DOCKER_URL.php

RUN chown -R www-data:www-data /usr/share/wordpress  

RUN usermod -d /var/lib/mysql/ mysql

RUN service mysql start; mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress;CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'whenguardian2021';GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';"

# setup supervisord to allow services to run in background
ADD supervisord /etc/supervisor/conf.d/

# RUN filebeat modules enable apache

# RUN filebeat modules enable mysql

RUN sed -i "s/{{ SURICATA_INTERFACE }}/$INTERFACE/g" /etc/supervisor/conf.d/suricata.conf

RUN sed -i "s/{{ TSHARK_INTERFACE }}/$INTERFACE/g" /etc/supervisor/conf.d/tshark.conf

RUN sed -i "s/{{ HOST_IP }}/$HOST_IP/g" /etc/supervisor/conf.d/tshark.conf

RUN mv /etc/supervisor/conf.d/tshark.conf /etc/supervisor/conf.d/tshark.conf.notused

RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
