#!/usr/bin/env bash

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

echo ">>> Installing Apache Server"

[[ -z "$1" ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

if [ -z "$2" ]; then
	public_folder="/vagrant"
else
	public_folder="$2"
fi


sudo rpm --import http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt
sudo rpm -ivh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm



# Update Again
sudo yum update -y

# Install Apache
sudo yum install -y httpd mod_fastcgi mod_ssl

echo ">>> Configuring Apache"



# Apache Config
#sudo a2enmod rewrite actions ssl
curl -L https://gist.githubusercontent.com/mikeyusc/10933456/raw/vhost.sh > vhost
sudo chmod guo+x vhost
sudo mv vhost /usr/local/bin

# Create a virtualhost to start, with SSL certificate
sudo vhost -s $1.xip.io -d $public_folder -p /etc/ssl/xip.io -c xip.io

sudo mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled

sudo touch /etc/httpd/conf.d/ssl.conf

sudo bash -c 'echo LoadModule ssl_module modules/mod_ssl.so >> /etc/httpd/conf.d/ssl.conf'
sudo bash -c 'echo Listen 443 >> /etc/httpd/conf.d/ssl.conf'


if [[ $PHP_IS_INSTALLED -eq 0 ]]; then
    # PHP Config for Apache
sudo sed -i "s/FastCgiWrapper .*/FastCgiWrapper Off/" /etc/httpd/conf.d/fastcgi.conf

sudo sed -i "s/listen = .*/listen = \/var\/run\/php5-fpm.sock/" /etc/php-fpm.d/www.conf

sudo bash -c 'cat > /etc/httpd/conf.d/php5-fpm.conf << EOF
<IfModule mod_fastcgi.c>
DirectoryIndex index.php
AddHandler php-fastcgi .php
Action php-fastcgi /php5-fcgi/php-fpm
ScriptAlias /php5-fcgi/ /var/www/php5-fcgi/
FastCGIExternalServer /var/www/php5-fcgi/php-fpm -socket /var/run/php5-fpm.sock -pass-header Authorization
</IfModule>

EOF'

sudo mkdir /var/www/php5-fcgi

#    sudo a2enconf php5-fpm
fi
sudo service php-fpm restart
sudo service httpd restart
