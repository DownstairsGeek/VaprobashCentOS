#!/usr/bin/env bash

if [ -z "$1" ]; then
    php_version="latest"
else
    php_version="$1"
fi

echo ">>> Installing PHP $1 version"


sudo yum update -y

# Install PHP
sudo yum --enablerepo=remi,remi-php55,remi-test install -y php-cli php-devel php-fpm php-pear php-mysqlnd php-pgsql php-sqlite php-curl php-gd php-gmp php-mcrypt php-memcached php-intl

sudo yum install -y ImageMagick ImageMagick-devel ImageMagick-perl
printf "\n" | sudo pecl install imagick

sudo bash -c 'echo extension=imagick.so >> /etc/php.ini'

sudo pecl install Xdebug

# xdebug Config
sudo bash -c 'cat > /etc/php.d/xdebug.ini << EOF
zend_extension=$(find /usr/lib64/php -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1

; var_dump display
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
EOF'

# PHP Error Reporting Config
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php.ini
sudo sed -i "s/html_errors = .*/html_errors = On/" /etc/php.ini

# PHP Date Timezone
sudo sed -i "s/;date.timezone =.*/date.timezone = ${2/\//\\/}/" /etc/php.ini

sudo service php-fpm restart
