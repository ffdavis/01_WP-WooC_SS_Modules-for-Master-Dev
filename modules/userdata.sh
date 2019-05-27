#!/bin/bash

exec &>> /home/ubuntu/userdata.log 2>&1

STOREONEEC2PUBIP=$1
STOREONEEC2DNSNAME=$2
SERVERNAMEALIAS="wpserver.net"

sudo su <<EOF
set -x

echo ""
echo "STEP 0 - DEFINE THE HOSTNAME AND ALIAS"
echo "-------------------------------------------------------------------------------------------"
echo ""
echo -e "${STOREONEEC2PUBIP} \t ${STOREONEEC2DNSNAME} \t ${SERVERNAMEALIAS}" >> /etc/hosts


echo ""
echo "STEP 1 - PREPARE AND UPDATE UBUNTU"
echo "-------------------------------------------------------------------------------------------"
echo ""
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime

apt update -y 
# apt full-upgrade -y 
DEBIAN_FRONTEND=noninteractive apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade
apt autoremove -y


echo ""
echo "STEP 2 - INSTALL APACHE2 WEB SERVER"
echo "-------------------------------------------------------------------------------------------"
apt install apache2 -y
sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/apache2/apache2.conf

# sed -i "s/Listen 80/Listen 80\nListen 8080/" /etc/apache2/ports.conf        # Set ports 80 and 8080 to listen
# sed -i "s/Listen 443/Listen 443\n\tListen 8443/" /etc/apache2/ports.conf    # Set ports 443 and 8443 to listen

sed -i "s/Listen 80/Listen 8080/" /etc/apache2/ports.conf                     # Set port 8080 to listen
sed -i "s/Listen 443/Listen 8443/" /etc/apache2/ports.conf                    # Set port 8443 to listen

systemctl stop apache2.service
systemctl start apache2.service
systemctl enable apache2.service


echo ""
echo "STEP 3: INSTALL MARIADB DATABASE SERVER"
echo "-------------------------------------------------------------------------------------------"
apt-get install mariadb-server mariadb-client -y
systemctl stop mariadb.service
systemctl start mariadb.service
systemctl enable mariadb.service
mysql_secure_installation <<EOF-MYSQLSECINST

y
cacarulo99
cacarulo99
y
y
y
y
EOF-MYSQLSECINST


echo ""
echo "STEP 4: INSTALL PHP AND RELATED MODULES"
echo "-------------------------------------------------------------------------------------------"
apt install -y php
apt install -y libapache2-mod-php
apt install -y php-common
apt install -y php-mbstring
apt install -y php-xmlrpc
apt install -y php-soap
apt install -y php-gd
apt install -y php-xml
apt install -y php-intl
apt install -y php-mysql
apt install -y php-cli

# Replace this "apt install -y php-mcrypt" for:
apt install -y php-dev 
apt install -y libmcrypt-dev 
apt install -y php-pear
pecl channel-update pecl.php.net
# pecl install mcrypt-1.0.1
# libmcrypt prefix? [autodetect] :
cat <(echo "") | pecl install mcrypt-1.0.1

# Open the /etc/php/7.2/cli/php.ini file and insert:
# extension=mcrypt.so
# or
sed -i "s/;extension=xsl/;extension=xsl \nextension=mcrypt.so/" /etc/php/7.2/cli/php.ini
sed -i "s/;extension=xsl/;extension=xsl \nextension=mcrypt.so/" /etc/php/7.2/apache2/php.ini
php -m | grep mcrypt

apt install -y php-ldap
apt install -y php-zip
apt install -y php-curl 
apt install -y php-json 
apt install -y php-cgi

sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/7.2/cli/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 256M/" /etc/php/7.2/cli/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 360/" /etc/php/7.2/cli/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/7.2/cli/php.ini

sed -i "s/post_max_size = 8M/post_max_size = 100M/" /etc/php/7.2/apache2/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 256M/" /etc/php/7.2/apache2/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 360/" /etc/php/7.2/apache2/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/7.2/apache2/php.ini


echo ""
echo " STEP 5: CREATE A BLANK WORDPRESS DATABASE"
echo "-------------------------------------------------------------------------------------------"
/usr/bin/mysql -u root -pcacarulo99 <<_EOF_
CREATE DATABASE WP_database;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'cacarulo99';
GRANT ALL ON WP_database.* TO 'wp_user'@'localhost' IDENTIFIED BY 'cacarulo99';
FLUSH PRIVILEGES;
_EOF_

echo ""
echo " STEP 6: CONFIGURE THE NEW WORDPRESS SITE"
echo "-------------------------------------------------------------------------------------------"

cat <<EOT_wordpress_conf >> /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:8080>                                           # Set port 8080 for Word Press
     ServerAdmin ffdavis@outlook.com
     DocumentRoot /var/www/html/wordpress/public_html
     ServerName ${SERVERNAMEALIAS}
     ServerAlias www.${SERVERNAMEALIAS}

     <Directory /var/www/html/wordpress/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
     </Directory>

     ErrorLog /var/www/html/wordpress/logs/error.log
     CustomLog /var/www/html/wordpress/logs/access.log combined

</VirtualHost>
EOT_wordpress_conf

mkdir -p /var/www/html/wordpress/{public_html,logs}
chown -R www-data:www-data /var/www/html/wordpress/public_html


echo ""
echo " STEP 7: ENABLE THE WORDPRESS SITE AND REWRITE MODULE"
echo "-------------------------------------------------------------------------------------------"
a2ensite wordpress.conf
a2enmod rewrite
a2dissite 000-default.conf                     # Disable 000-default.conf 

sudo systemctl reload apache2


echo ""
echo "STEP 8: INSTALL PHP TEST page and TROUBLESHOOT the LAMP STACK"
echo "-------------------------------------------------------------------------------------------"

mv /home/ubuntu/phptest.php /var/www/html/wordpress/public_html/phptest.php

# NOTE: Navigate to ec2dnsname/phptest.php
#       If the components of your LAMP stack are working correctly, the browser will display a Connected successfully message. 
#       If not, the output will be an error message.


echo ""
echo "STEP 9 - INSTALL WP-CLI"
echo "-------------------------------------------------------------------------------------------"
echo ""

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
wp --info

mkdir -p /home/ubuntu/.wp-cli/cache
chown -R www-data:www-data /home/ubuntu/.wp-cli/


echo ""
echo "STEP 10 - INSTALL NGINX AND CONFIGURE IT AS REVERSE PROXY"
echo "-------------------------------------------------------------------------------------------"
echo ""

apt install nginx -y

unlink /etc/nginx/sites-enabled/default

cat <<EOF_revprox_conf >> /etc/nginx/sites-available/reverse-proxy.conf
server {
        listen 80;
        listen [::]:80;

        access_log /var/log/nginx/reverse-access.log;
        error_log /var/log/nginx/reverse-error.log;

        location / {
                    proxy_pass http://127.0.0.1:8080;
        }
}
EOF_revprox_conf

ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf

# nginx -t

systemctl restart nginx

EOF

set -x

echo ""
echo "STEP 11 - INSTALL WORDPRESS USING WP-CLI ON UBUNTU 18.04"
echo "-------------------------------------------------------------------------------------------"
echo ""

cd /var/www/html/wordpress/public_html

sudo -u www-data wp core download

sudo -u www-data wp core config --dbname='WP_database' --dbuser='wp_user' --dbpass='cacarulo99' --dbhost='localhost' --dbprefix='wp_'

sudo -u www-data wp core install --url='http://wpserver.net:8080' --title='Blog Title' --admin_user='adminfer' --admin_password='cacarulo99' --admin_email='ffdavis@ook.com' # Add port 8080 here for WP

sudo -u www-data wp plugin search woocommerce
sudo -u www-data wp plugin install woocommerce
sudo -u www-data wp plugin activate woocommerce
sudo -u www-data wp plugin list

echo ""
echo "STEP 12 - INSTALL THEMES"
echo "-------------------------------------------------------------------------------------------"
echo ""

cd /var/www/html/wordpress/public_html

# To search for a theme:
# wp theme search basic

# To install and activate a theme:
sudo -u www-data wp theme install basic
sudo -u www-data wp theme activate basic

<<COMMENT
1.- HOW TO CHECK THAT APACHE2 IS RUNNING:

  $ sudo netstat -tlpn | grep apache2
  $ sudo netstat -tulpn
    It shows apache2 running on ports 80 and 8080

    Check with:
  $ curl -i IP-address
 
    Reload and restart Apache
  $ sudo systemctl reload apache2
  $ sudo systemctl restart apache2

2.- QUERIES FOR MARIADB TO CHECK THE URL CONFIGURATION:

  $ sudo /usr/bin/mysql -u root -pcacarulo99

  > use WP_database
  > select * from wp_options where option_name = 'home' OR option_name = 'siteurl';

  option_id | option_name | option_value             | autoload |
  +-----------+-------------+--------------------------+----------+
  |         2 | home        | http://wpserver.net:8080 | yes      |
  |         1 | siteurl     | http://wpserver.net:8080 | yes      |
  +-----------+-------------+--------------------------+-------

  > UPDATE `table_name` 
    SET `field_name` = replace(field_name, 'old_text', 'new_text')

  > UPDATE wp_options 
    SET option_value = replace(option_value, 'http://www.oldurl.com:80','http://www.newurlcom:8080') 
    WHERE option_name = 'home' OR option_name = 'siteurl';

3.- HOW TO GET AND SET THE HOME AND SITEURL IN THE WORDPRESS DB
  cd /var/www/html/wordpress/public_html
  sudo -u www-data wp option get siteurl
  sudo -u www-data wp option update home 'http://wpserver.net:8080'
  sudo -u www-data wp option update siteurl 'http://wpserver.net:8080'

COMMENT
