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

RUN apt install wordpress php libapache2-mod-php mysql-server php-mysql -y

#https://ubuntu.com/tutorials/install-and-configure-wordpress#1-overview

ADD config/wordpress.conf /etc/apache2/sites-available/

RUN a2ensite wordpress

RUN a2enmod rewrite

RUN service apache2 reload

RUN mysql -u root -e "CREATE DATABASE wordpress; GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER -> ON wordpress.* -> TO wordpress@localhost -> IDENTIFIED BY '<whenguardian2021>';

ADD config/config-localhost.php /etc/wordpress/

RUN service mysql start

ADD supervisord /etc/supervisor/conf.d/

RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
