# Install ERPNEXT on Debian Buster 10.x on GKE - python 3.x

## Prerequisites

This tutorial assumes you have created a VM in Google Cloud. We will use `erp.mydomain.com` as our domain pointed to the server. Please make sure to replace all occurrences of `erp.mydomain.com` with your actual domain name.

- Debian Buster 10.x
- Root login details

Tools we are installing include

<pre>
• Python 3.6+
• Node.js 12
• Redis 5					              (Caching and realtime updates)
• MariaDB 10.3 / Postgres 9.5			  (to run database driven apps)
• yarn 1.12+					          (js dependency manager)
• pip 15+					              (py dependency manager)
• cron 						              (scheduled jobs)
• wkhtmltopdf                             (version 0.12.5 with patched qt) 	(for pdf generation)
• Nginx 					              (for production)
</pre>

### Login as `Root` and upgrade server

Lets perform initial preparation steps as `root`

``` bash
sudo su - root
apt update -y && apt upgrade -y
```

## Create `frappe` user

Add user `frappe` and add `frappe` user to `sudo` group

``` bash 
# Confirm login defaults in cat /etc/login.defs or /etc/default/useradd
useradd -m -s /bin/bash frappe 
passwd frappe
usermod -aG sudo frappe
```
## Install Essential software and tools

``` bash
apt -y update && apt install -y sshfs gcc wget binutils net-tools dnsutils lsof dirmngr curl ca-certificates apt-transport-https software-properties-common mc git-core build-essential network-manager locales build-essential cron sudo git supervisor nginx gettext-base
    
# Check your nginx install
curl http://localhost
# Check git version
git --version
git version 2.20.1
```

## Set locales - Optional 

``` bash
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
dpkg-reconfigure locales
# Choose en_US.UTF-8
```

## Install Python3 and Development tools

Frappé requires at least Python 2.7 installed, but Python3.5+ is also supported. Most Linux OS distributions are shipped with Python. However, we might require the python-dev package installed for using Python's C API. 

**Install python 3.x, `Setuptools` and `Pip` (Python's package Manager)**

``` bash
apt -y install python3-dev python3-setuptools python3-pip
```
    
## Install and configure MariaDB server

Frappé uses MariaDB for RDBMS as its database engine. During this installation you'll be prompted to set the MySQL root password. If you are not prompted for the password, you'll have to initialize the MySQL server setup yourself after the installation is complete. 

``` bash
# Add MySQL server signing key
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
apt update -y && apt install -y mariadb-client mariadb-server mariadb-common libmariadb3 python3-mysqldb

# Test the MySQL installation
mysql -u root
MariaDB [(none)]> SELECT VERSION();
+---------------------------+
| VERSION()                 |
+---------------------------+
| 10.3.22-MariaDB-0+deb10u1 |
+---------------------------+
1 row in set (0.000 sec)

exit
```

Since no password for MySQL was set, You can initialize the MySQL server setup by executing the following command to secure your MySQL installation

``` bash
mysql_secure_installation
```

``` bash
# GRANT root permissions access
# mysqladmin -u root password 'YourMYSQLpassword'

mysql -u root -p -Bse "GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.%.%.%' IDENTIFIED BY '$MySQLpass' WITH GRANT OPTION;"
mysql -u root -p -Bse "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MySQLpass' WITH GRANT OPTION;"
```

## Install NodeJS 10.x, Redis Server and Yarn package manager

Install Node.js 10.X package 

``` bash
# This installs v10.x, for v8 change "setup_10.x" to "setup_8.x")
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash - 
apt update && apt install -y nodejs

# Yarn package manager
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt update && apt install -y yarn

# Install Redis Server
apt install redis-server -y

# Test the installs `node -v && npm -v && yarn -v && redis-server -v`
root@erpnext01:~# node -v && npm -v && yarn -v && redis-server -v
v10.19.0
6.13.4
1.21.1
Redis server v=5.0.3 sha=00000000:0 malloc=jemalloc-5.1.0 bits=64 build=afa0decbb6de285f
```

## Install `wkhtmltopdf`  PDF Converter

The wkhtmltopdf program is a command line tool that converts HTML into PDF using the QT Webkit rendering engine. 

Install the required dependencies.

``` bash
apt install -y xfonts-75dpi fontconfig libxrender1 xfonts-base libxext6
```

The default apt-get version is outdated. Install pre-reqs, and then a manual/latest version

``` bash
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
dpkg --install wkhtmltox_0.12.5-1.stretch_amd64.deb
```

## Install Python Tools

```bash
apt update -y && apt install -y libmariadbclient-dev python-mysqldb python-pdfkit libssl-dev python-dateutil python-pip-whl python-distribute python3-cxx-dev python3-dev python-virtualenv

pip3 install --upgrade mysqlclient
```

## MySQL Custom settings for ERPnext

``` bash
cat <<EOF >> /etc/mysql/my.cnf

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[my
default-character-set = utf8mb4
EOF

# Restart MySQL
systemctl restart mysql

# Restart Server
reboot
```

## Login as FRAPPE user

``` bash
sudo su -l frappe

git clone https://github.com/frappe/bench bench-repo
sudo pip3 install -e bench-repo
```

## Create a new bench

The init command will create a bench directory with frappe framework installed. It will be setup for periodic backups and auto updates once a day

``` bash
bench init frappe-bench --frappe-branch master && cd frappe-bench
```

## Add a site

Frappe apps are run by frappe sites and you will have to create at least one site. The new-site command allows you to do that.

``` bash
bench new-site site1.local
``` 

## Start bench

To start using the bench, use the bench start command

``` bash
bench start
```

## Optional: Fix missing Werkzeug module error after running `bench start`

cd ${HOME}/frappe-bench
./env/bin/pip install werkzeug==0.16.0

# Test access to site

To login to Frappe / ERPNext, open your browser and go to [your-external-ip]:8000, or localhost:8000
The default logins: Username is "Administrator" and Password is what you set when you created the new site.

# Reboot the server

``` bash
sudo reboot
```

``` bash
# Make sure you are logged in as FRAPPE User
cd frappe-bench
bench get-app erpnext https://github.com/frappe/erpnext --branch master
bench --site site1.local install-app erpnext

# Switch to Production as this is Develop
sudo bench setup production frappe

# Check bench version
bench version
```

## Test to see if server is working 

curl http://ifconfig.co
curl http://IP:port

# Upgrade ERPnext

``` bash
# Edit `~/frappe-bench/apps/erpnext/.git/config`
sed -i.bak 's/\/master/\/*/g' ~/frappe-bench/apps/erpnext/.git/config

# Switch to version-12 branch and Upgrade

bench switch-to-branch version-12 frappe erpnext --upgrade
bench update --patch

frappe@erpnext03:~/frappe-bench$ bench version
erpnext 12.4.3
frappe 11.1.44

```
## Lets Fix branch issue with versions

``` bash
frappe@erpnext01:~/frappe-bench$ bench version
erpnext 12.4.3
frappe 11.1.44
```

Erpnext has been upgraded to v12 but Frappe wasn't. We have to reconfigure our git. Since you are working in `~/frappe-bench` change directory into `~/frappe-bench/apps/frappe`

``` bash
git config remote.upstream.fetch +refs/heads/*:refs/remotes/upstream/*
git config --get remote.upstream.fetch #git fetch upstream works too
```

Do the same steps and change into erpnext app directory `~/frappe-bench/apps/erpnext`

``` bash
git config remote.upstream.fetch +refs/heads/*:refs/remotes/upstream/*
git config --get remote.upstream.fetch #git fetch upstream works too
```
Change directory into `~/frappe-bench/`.

``` bash
bench switch-to-branch version-12 frappe erpnext --upgrade
bench update --patch

# Received lots of errors after this and plugins missing

bench update --build
bench update --reset

```

My results

``` bash
frappe@erpnext01:~/frappe-bench$ bench version
erpnext 12.4.3
frappe 12.2.1
```

## Troubleshooting

``` bash
#Restart all services
sudo supervisorctl stop all
sudo supervisorctl start all
sudo supervisorctl status

Or

bench restart



## Stopping Production and starting Development

``` bash
cd frappe-bench
bench switch-to-develop (Optional : Will change your branches to the "develop" branch)
rm config/supervisor.conf
rm config/nginx.conf
```
Remove 'restart_supervisor_on_update' from sites/common_site_config.json if it exists

``` bash
sudo service nginx stop
sudo service supervisor stop
bench setup procfile
bench start
```

To serve a specific site in multi-site environment, set it as default site##

``` bash
bench use <site_name>
bench start
```

## Fix Bench errors GitPython and PyYAML

Error: bench 4.1.0 has requirement GitPython==2.1.11, but you'll have gitpython 2.1.15 which is incompatible.
ERROR: frontmatter 3.0.5 has requirement PyYAML==3.13, but you'll have pyyaml 5.1 which is incompatible.

``` bash
python3 -m pip install GitPython==2.1.11
python3 -m pip install PyYAML==3.13
```

## Point A record to the server IP's

- Im using cloudflare

## Drop the local sites

bench drop-site site1.local

## Setup DNS based multitenancy

You can name your sites as the hostnames that would resolve to it. 
Thus, all the sites you add to the bench would run on the same port and will be automatically selected based on the hostname.
For example: erp.example.com, erp-dev.example.com, erp.customer.com

To make a new site under DNS based multitenancy, perform the following steps.

``` bash
# Switch on DNS based multitenancy (once)
bench config dns_multitenant on
```

## Create a new site

``` bash
bench new-site erp.larrydevops.com
```

## Add a custom domain to my site

On running the command you will be asked for which site you want to set the custom domain for :erp.larrydevops.com 

``` bash
bench setup add-domain erp.larrydevops.com
```

## The top 2 commands require you to Regenerate your nginx config

``` bash
bench setup nginx # ovewrite nginx: yes
```

## Reload nginx

``` bash
sudo systemctl reload nginx
sudo service nginx reload
# /etc/nginx/conf.d/frappe-bench.conf
```

Note: Do not login to sites before you add ERPNEXT App

## Add erpnext app to site

``` bash
bench --site erp.larrydevops.com install-app erpnext

```

## Access the site and Setup ERPnext

Access the site on http://erp.larrydevops.com

## Troubleshooting section

Use dns tools to check DNS Propagation

https://dnschls -al;ecker.org/
https://www.whatsmydns.net/
https://dnsmap.io/

### Change Sites

Your first site is automatically set as default site. You can change it with the command

``` bash
bench use erp.larrydevops.com
```

## Using Let's Encrypt to setup HTTPS

### Prequisites

- You need to have a DNS Multitenant Setup
- Your site should be accessible via a valid domain
- You need root permissions on your server

* Note: Let's Encrypt Certificates expire every three months **

I'm setting up Let's Encrypt for Custom domain. Just use the `--custom-domain` option

``` bash
sudo -H bench setup lets-encrypt erp.larrydevops.com --custom-domain erp.larrydevops.com
# overwite nginx: y
```

### Renew Let's Encrypt Certificates manually

To renew certificates manually you can use:

``` bash
sudo bench renew-lets-encrypt
```

## Restore a database

``` bash
mysql -u root -p
show databases;
drop database [database-name];
```

## Download Database Backup

``` bash
wget https://
gunzip [DATABASE BACKUP FILE.sql.gz]
tar xvf [FILES BACKUP.tar]
```

bench --site erp.larrydevops.com --force restore /path/to/SQLFILE.sql
bench --site erp.larrydevops.com --migrate

## To Reset Admin password

bench --site erp.larrydevops.com set-admin-password Password
