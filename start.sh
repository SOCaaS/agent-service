#!/bin/bash
set -e
set -x

echo -e "\nUpdate and Upgrade"
apt update
apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy dist-upgrade

echo -e "\nNameserver to Cloudflare"
sed -i -e "s|nameserver.*|nameserver 1.1.1.1|g" /etc/resolv.conf

if [ -f .env ]
then
    echo -e "\nImporting .do.env to Environment Variable"
    set -o allexport; source .do.env; set +o allexport
else 
    echo -e "\nThere is no env file!"
    exit 1
fi

# install filebeat https://www.elastic.co/guide/en/beats/filebeat/current/setup-repositories.html
echo "Installing filebeat"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

apt install -y apt-transport-https

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

apt update

apt install -y filebeat

echo "replacing filebeat.yml"
cp filebeat.yml /etc/filebeat/filebeat.yml

echo "installing tshark"
DEBIAN_FRONTEND=noninteractive apt install -y tshark

echo "copy tshark.service to /etc/systemd/system"
cp tshark.service /etc/systemd/system/

echo "create /tshark"
mkdir /tshark

sed -i "s/{{ TSHARK_INTERFACE }}/$INTERFACE/g" tshark.sh
chmod +x tshark.sh
cp tshark.sh /tshark

add-apt-repository ppa:oisf/suricata-stable -y

apt update

apt install suricata suricata-dbg -y

sed -i "s/{{ HOST_IP }}/[$HOST_IP]/g" suricata.yaml

cp detect-dos.rules /etc/suricata/rules

cp suricata.yaml /etc/suricata

suricata-update

service filebeat start

apt -y install mysql-server

apt -y install wordpress

apt -y install apache2

mysql -u root -e "CREATE DATABASE IF NOT EXISTS wordpress;CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'whenguardian2021';GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';"

cp config/wordpress.conf /etc/apache2/sites-available

a2ensite wordpress

a2enmod rewrite

service apache2 restart

cp config/config.php /etc/wordpress/config-$URL.php

chown -R www-data:www-data /usr/share/wordpress

