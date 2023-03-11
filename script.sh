#!/bin/bash
ip=10.1.0.4

sleep 30

sudo apt update
sudo apt -y upgrade

sudo apt -y install ansifilter

sudo apt -y install traceroute

sudo apt -y install apache2

sudo systemctl start apache2
sudo systemctl enable apache2

sudo chown -R $USER:$USER /var/www
cd /var/www/html/

echo '<!DOCTYPE html>' > index.html
echo '<html>' >> index.html
echo '<head>' >> index.html
echo '<title>Network Test</title>' >> index.html
echo '<meta charset="UTF-8">' >> index.html
echo '</head>' >> index.html
echo '<body>' >> index.html
echo '<h1>Traceroute a la máquina de WestEurope desde la Máquina EastUS</h1>' >> index.html
traceroute $ip > traceroute
ansifilter -i traceroute -H -s 250 >> index.html
echo '' >> test.html
echo '<h1>Ping a la máquina de WestEurope desde la Máquina EastUS</h1>' >> index.html
ping -c 4 $ip > ping
ansifilter -i ping -H -s 250 >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html

rm traceroute
rm ping

sudo systemctl apache2 restart

echo "Script terminado"