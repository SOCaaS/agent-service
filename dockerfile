FROM base/ubuntu-supervisor:latest

LABEL type="filebeat2"

RUN apt update

RUN apt upgrade -y

RUN apt-get update && apt-get install -y gnupg2

RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

RUN apt install -y apt-transport-https

RUN echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

RUN apt update

RUN apt install -y filebeat

ADD filebeat.yml /etc/filebeat/filebeat.yml

RUN apt install -y tshark

RUN mkdir /tshark

RUN apt update

RUN apt-get install software-properties-common -y

RUN add-apt-repository ppa:oisf/suricata-stable -y

RUN apt update && apt upgrade -y

RUN apt install suricata suricata-dbg -y

ADD detect-dos.rules /etc/suricata/rules

ADD suricata.yaml /etc/suricata

RUN suricata-update

RUN filebeat modules enable suricata

# Install wordpress, mysql server and apache2

RUN apt update

RUN apt install wordpress -y

RUN apt install apache2 -y

RUN apt install mysql-server -y

ADD /config/wordpress.conf /etc/apache2/sites-available

RUN a2ensite wordpress
RUN a2enmod rewrite
RUN service apache2 reload
RUN service apache2 restart

ADD /config/config-10.0.2.95.php /etc/wordpress

RUN service mysql stop

RUN usermod -d /var/lib/mysql/ mysql

RUN service mysql start

RUN mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress;CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'whenguardian2021';GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';"

ADD supervisord /etc/supervisor/conf.d/

RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
