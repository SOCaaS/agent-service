#!/bin/bash
set -e

echo -e "\nUpdate and Upgrade"
apt update
apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy dist-upgrade

echo -e "\nNameserver to Cloudflare"
sed -i -e "s|nameserver.*|nameserver 1.1.1.1|g" /etc/resolv.conf

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
apt install -y tshark

echo "copy tshark.service to /etc/systemd/system"
cp tshark.service /etc/systemd/system/

echo "create /tshark"
mkdir /tshark

chmod +x tshark.sh
cp tshark.sh /tshark

add-apt-repository ppa:oisf/suricata-stable -y

apt update

apt install suricata suricata-dbg -y

cp detect-dos.rules /etc/suricata/rules

cp suricata.yaml /etc/suricata

suricata-update

filebeat modules enable suricata

service filebeat start
