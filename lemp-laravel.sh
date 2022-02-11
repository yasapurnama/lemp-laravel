#!/bin/bash

# Text Colour
RED="\033[01;31m"    # Issues/Errors
GREEN="\033[01;32m"  # Success
YELLOW="\033[01;33m" # Warnings/Information
BLUE="\033[01;34m"   # Heading
BOLD="\033[01;01m"   # Highlight
RESET="\033[00m"     # Normal

# Check if running as root
if [[ "${EUID}" -ne 0 ]]; then
    echo -e "${RED}[!]${RESET} This script must be ${RED}run as root${RESET}" 1>&2
    exit 1
fi

# Variables
USERNAME=""
PASSWORD=""
MYSQL_ROOT_PASSWORD=""
PROJECT_DIRECTORY=""
DOMAIN_NAME=""
DOMAIN_EMAIL=""

#Advance Configuration
PHP_VERSION="7.4" # change base on your need, see LTS support https://www.php.net/supported-versions.php
PHPMYADMIN_VERSION="5.1.1" # check latest version https://www.phpmyadmin.net/downloads/
NVM_VERSION="v0.39.0" # check latest version https://github.com/nvm-sh/nvm/releases
NODE_VERSION="v16.13.1" # change base on your need, see LTS support https://nodejs.org/en/about/releases/

#nginx
NGINX_MAX_BODY_SIZE="64M"

#php.ini
PHP_MEMORY_LIMIT="128M"
PHP_UPLOAD_MAX_FILESIZE="5M"
PHP_POST_MAX_SIZE="5M"
PHP_MAX_EXECUTION_TIME="300"
PHP_MAX_INPUT_TIME="300"
PHP_MAX_FILE_UPLOAD="100"

#php-fpm
FPM_MAX_CHILDREN="50"
FPM_START_SERVERS="20"
FPM_MIN_SPARE_SERVERS="10"
FPM_MAX_SPARE_SERVERS="20"
FPM_MAX_REQUESTS="500"

#redis
REDIS_MAX_MEMORY="128mb"

MYSQL_PROD_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16})
MYSQL_DEV_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16})
MYSQL_STAGING_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16})
SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PHP_FPM_POOL_DIR="/etc/php/${PHP_VERSION}/fpm/pool.d"
PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
NGINX_SITEAVAILABLE_DIR="/etc/nginx/sites-available"
NGINX_SITEENABLE_DIR="/etc/nginx/sites-enabled"
LOG_FILE="install_log.txt"


# Setup Varibales
while [[ $USERNAME == "" ||  $PASSWORD == "" || $MYSQL_ROOT_PASSWORD == ""  || $PROJECT_DIRECTORY == "" ]]
do
    clear
    which curl > /dev/null 2>&1 && curl https://raw.githubusercontent.com/yasapurnama/lemp-laravel/master/banner.txt
    echo -e "${GREEN}Wellcome to LEMP stack installation for Laravel application${RESET}\n"
    echo -e "You need to fillup the following variables:"
    echo -e "USERNAME=${USERNAME}"
    [[ $PASSWORD == "" ]] && echo -e "PASSWORD=" || echo -e "PASSWORD=********"
    [[ $MYSQL_ROOT_PASSWORD == "" ]] && echo -e "MYSQL_ROOT_PASSWORD=" || echo -e "MYSQL_ROOT_PASSWORD=********"
    echo -e "PROJECT_DIRECTORY=${PROJECT_DIRECTORY}"
    echo -e "DOMAIN_NAME=${DOMAIN_NAME}"
    echo -e "DOMAIN_EMAIL=${DOMAIN_EMAIL}"
    echo ""

    if [[ $USERNAME == "" ]]; then
        echo -e "${GREEN}[*]${RESET} Setup Varibales:"
        echo -n "USERNAME:"
        read USERNAME
    fi

    if [[ $PASSWORD == "" ]]; then
        echo -n "PASSWORD:"
        read -s PASSWORD
    fi

    if [[ $MYSQL_ROOT_PASSWORD == "" ]]; then
        echo -en "\nMYSQL_ROOT_PASSWORD:"
        read -s MYSQL_ROOT_PASSWORD
    fi

    if [[ $PROJECT_DIRECTORY == "" ]]; then
        echo -en "\nPROJECT_DIRECTORY:"
        read PROJECT_DIRECTORY
    fi

    if [[ $DOMAIN_NAME == "" ]]; then
        echo -n "DOMAIN_NAME:"
        read DOMAIN_NAME
    fi

    if [[ $DOMAIN_EMAIL == "" ]]; then
        echo -n "DOMAIN_EMAIL:"
        read DOMAIN_EMAIL
    fi

done

check_cmd_status() {
    if [[ "$?" -ne 0 ]]; then
        echo -e "\n"
        echo -e "${RED}[!]${RESET} There was an ${RED}issue on $1 ${RESET}" 1>&2
        echo -e "${YELLOW}[i]${RESET} Check log file: ${LOG_FILE}" 1>&2
        exit 1
    fi
}



# Start Server Installation
echo -e "\n"
echo -e "${GREEN}[*]${RESET} Start Installation.."
sleep 3s


# Keep operating system up to date
echo -e "${GREEN}[*]${RESET} Update system.."

apt -y update &> ${LOG_FILE}
check_cmd_status "update system.."

apt -y upgrade >> ${LOG_FILE} 2>&1
check_cmd_status "upgrade system.."


# Install Nginx, Net Tools, Git, Zip
echo -e "${GREEN}[*]${RESET} Install nginx wget curl net-tools git unzip htop nano apache2-utils supervisor cron redis-server software-properties-common nodejs npm build-essential.."

apt -y install nginx wget curl net-tools git unzip htop nano apache2-utils supervisor cron redis-server software-properties-common nodejs npm build-essential >> ${LOG_FILE} 2>&1
check_cmd_status "install nginx wget curl net-tools git unzip htop nano apache2-utils supervisor cron redis-server software-properties-common nodejs npm build-essential.."


# Install MySQL
echo -e "${GREEN}[*]${RESET} Install & Configure MySQL.."

apt -y install debconf-utils >> ${LOG_FILE} 2>&1
check_cmd_status "install debconf-utils.."

debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" >> ${LOG_FILE} 2>&1
check_cmd_status "debconf-set password.."

debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" >> ${LOG_FILE} 2>&1
check_cmd_status "debconf-set password_again.."

apt -y install mysql-server >> ${LOG_FILE} 2>&1
check_cmd_status "install mysql-server.."


# Install PHP
echo -e "${GREEN}[*]${RESET} Install PHP.."

add-apt-repository -y universe >> ${LOG_FILE} 2>&1
check_cmd_status "add repository universe.."

add-apt-repository -y ppa:ondrej/php >> ${LOG_FILE} 2>&1
check_cmd_status "add repository ppa:ondrej/php.."

apt -y -qq update >> ${LOG_FILE} 2>&1
check_cmd_status "update repository.."

apt install -y php${PHP_VERSION}-{fpm,mysql,mbstring,xml,zip,soap,gd,curl,imagick,cli,bcmath,redis} >> ${LOG_FILE} 2>&1
check_cmd_status "install php.."

update-alternatives --set php $(which php${PHP_VERSION})


# Configure PHP
echo -e "${GREEN}[*]${RESET} Configure php.ini.."

if ! grep -q "; Custom PHP.ini config" ${PHP_INI}; then
cat <<EOF >> ${PHP_INI}

; Custom PHP.ini config
memory_limit = ${PHP_MEMORY_LIMIT}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
post_max_size = ${PHP_POST_MAX_SIZE}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_time = ${PHP_MAX_INPUT_TIME}
max_file_uploads = ${PHP_MAX_FILE_UPLOAD}
EOF
check_cmd_status "configure php.ini.."
fi

# Install Composer
echo -e "${GREEN}[*]${RESET} Install Composer.."

curl -sS https://getcomposer.org/installer | php >> ${LOG_FILE} 2>&1
check_cmd_status "get composer.."

cp -f composer.phar /usr/local/bin/composer >> ${LOG_FILE} 2>&1
check_cmd_status "install composer.."

rm composer.phar >> ${LOG_FILE} 2>&1
check_cmd_status "remove file composer.."


# Start User Based Config
echo -e "${GREEN}[*]${RESET} Add new user.."

adduser ${USERNAME} --disabled-login --gecos "LEMP User"  >> ${LOG_FILE} 2>&1
echo "${USERNAME}:${PASSWORD}" | chpasswd >> ${LOG_FILE} 2>&1
check_cmd_status "add new user.."


echo -e "${GREEN}[*]${RESET} Allow user login with password.."
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config >> ${LOG_FILE} 2>&1
check_cmd_status "allow user login via password.."

systemctl restart ssh >> ${LOG_FILE} 2>&1
check_cmd_status "restart ssh service.."


# Download & Config phpMyAdmin
echo -e "${GREEN}[*]${RESET} Download and Configure phpMyAdmin.."
wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-english.tar.gz -P /tmp >> ${LOG_FILE} 2>&1
check_cmd_status "download phpMyAdmin.."

tar xvzf /tmp/phpMyAdmin-${PHPMYADMIN_VERSION}-english.tar.gz >> ${LOG_FILE} 2>&1
check_cmd_status "extract phpMyAdmin.."

cp -rf phpMyAdmin-${PHPMYADMIN_VERSION}-english /home/${USERNAME}/phpmyadmin >> ${LOG_FILE} 2>&1
check_cmd_status "copy phpMyAdmin.."

rm -rf phpMyAdmin-${PHPMYADMIN_VERSION}-english >> ${LOG_FILE} 2>&1
check_cmd_status "remove source phpMyAdmin.."

sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$(openssl rand -base64 32)'|" /home/${USERNAME}/phpmyadmin/config.sample.inc.php > /home/${USERNAME}/phpmyadmin/config.inc.php >> ${LOG_FILE} 2>&1
check_cmd_status "Set blowfish secret phpMyAdmin.."

mkdir -p /home/${USERNAME}/phpmyadmin/tmp; chmod 777 /home/${USERNAME}/phpmyadmin/tmp >> ${LOG_FILE} 2>&1
check_cmd_status "create tmp dir phpMyAdmin.."

echo -e "${GREEN}[*]${RESET} Generate user htpasswd.."

echo $PASSWORD | htpasswd -c -i /home/${USERNAME}/.htpasswd ${USERNAME} >> ${LOG_FILE} 2>&1
check_cmd_status "generate user htpasswd.."


# Set Project git & directory 
echo -e "${GREEN}[*]${RESET} Set project directory.."

mkdir -p /home/${USERNAME}/public_html/${PROJECT_DIRECTORY}/prod >> ${LOG_FILE} 2>&1
check_cmd_status "create project directory prod.."

mkdir -p /home/${USERNAME}/public_html/${PROJECT_DIRECTORY}/dev >> ${LOG_FILE} 2>&1
check_cmd_status "create project directory dev.."

mkdir -p /home/${USERNAME}/public_html/${PROJECT_DIRECTORY}/staging >> ${LOG_FILE} 2>&1
check_cmd_status "create project directory staging.."

mkdir -p /home/${USERNAME}/git >> ${LOG_FILE} 2>&1
check_cmd_status "create git directory.."

chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} >> ${LOG_FILE} 2>&1
check_cmd_status "chown user dir.."


# Configure php-fpm for user
echo -e "${GREEN}[*]${RESET} Configure php-fpm.."

# Backup default php-fpm config
[[ -f ${PHP_FPM_POOL_DIR}/www.conf ]] && mv ${PHP_FPM_POOL_DIR}/www.conf{,.bckp} >> ${LOG_FILE} 2>&1

# Create new php-fpm config (project specify)
PHP_FPM_SOCK="/var/run/php-fpm-${USERNAME}.sock"

cat <<EOF > ${PHP_FPM_POOL_DIR}/${USERNAME}.conf
[${USERNAME}]
user = ${USERNAME}
group = ${USERNAME}
listen = ${PHP_FPM_SOCK}
listen.owner = ${USERNAME}
listen.group = ${USERNAME}
pm = dynamic
pm.max_children = ${FPM_MAX_CHILDREN}
pm.start_servers = ${FPM_START_SERVERS}
pm.min_spare_servers = ${FPM_MIN_SPARE_SERVERS}
pm.max_spare_servers = ${FPM_MAX_SPARE_SERVERS}
pm.max_requests = ${FPM_MAX_REQUESTS}
EOF
check_cmd_status "create new php-fpm config.."

systemctl restart php${PHP_VERSION}-fpm >> ${LOG_FILE} 2>&1
check_cmd_status "restart php-fpm service.."


# Install Certbot via Snap
echo -e "${GREEN}[*]${RESET} Install Certbot.."

snap install core >> ${LOG_FILE} 2>&1
check_cmd_status "install snap.."

snap refresh core >> ${LOG_FILE} 2>&1
check_cmd_status "refresh snap.."

snap install --classic certbot >> ${LOG_FILE} 2>&1
check_cmd_status "install certbot.."

ln -sf /snap/bin/certbot /usr/bin/certbot >> ${LOG_FILE} 2>&1
check_cmd_status "link certbot.."


echo -e "${GREEN}[*]${RESET} Generate SSL Certificate.."

PROD_DOMAIN_IP=$(dig +short ${DOMAIN_NAME} A)
DEV_DOMAIN_IP=$(dig +short dev.${DOMAIN_NAME} A)
STAGING_DOMAIN_IP=$(dig +short staging.${DOMAIN_NAME} A)

CERT_COMMENT="# "
CERT_UNCOMMENT=""
REQUEST_DOMAINS=""

if [[ $PROD_DOMAIN_IP == $SERVER_IP ]]; then

  REQUEST_DOMAINS="${DOMAIN_NAME}"
  [[ DEV_DOMAIN_IP == $SERVER_IP ]] && REQUEST_DOMAINS="${REQUEST_DOMAINS},dev.${DOMAIN_NAME}"
  [[ STAGING_DOMAIN_IP == $SERVER_IP ]] && REQUEST_DOMAINS="${REQUEST_DOMAINS},staging.${DOMAIN_NAME}"

  certbot certonly --nginx --non-interactive --agree-tos --domains ${REQUEST_DOMAINS} --email ${DOMAIN_EMAIL} >> ${LOG_FILE} 2>&1

  certbot renew --dry-run >> ${LOG_FILE} 2>&1

  [[ -f /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem ]] && CERT_COMMENT="" && CERT_UNCOMMENT="# "

fi


# Configure nginx
echo -e "${GREEN}[*]${RESET} Configure nginx.."

sed -i "s/user www-data;/user ${USERNAME};/g" /etc/nginx/nginx.conf >> ${LOG_FILE} 2>&1
check_cmd_status "set default nginx user.."

sed -i 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/nginx.conf >> ${LOG_FILE} 2>&1
check_cmd_status "uncomment server_tokens off.."

cat <<EOF > ${NGINX_SITEAVAILABLE_DIR}/${DOMAIN_NAME}.conf
server {
        listen 80;
        ${CERT_COMMENT}listen 443 ssl http2;
        server_name ${DOMAIN_NAME};

        ${CERT_COMMENT}ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
        ${CERT_COMMENT}ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;
        ${CERT_COMMENT}include /etc/letsencrypt/options-ssl-nginx.conf;
        ${CERT_COMMENT}ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

        ${CERT_COMMENT}ssl_stapling on;
        ${CERT_COMMENT}ssl_stapling_verify on;
        ${CERT_COMMENT}ssl_trusted_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
        resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 valid=3600s;
        resolver_timeout 5s;

        client_max_body_size ${NGINX_MAX_BODY_SIZE};

        # phpmyadmin
        location /phpmyadmin {
                auth_basic "Restricted Content";
                auth_basic_user_file /home/${USERNAME}/.htpasswd;

                root /home/${USERNAME};
                index index.php index.html index.htm;
                location ~ ^/phpmyadmin/(.+\.php)\$ {
                        try_files \$uri \$uri/ =404;
                        fastcgi_pass unix:${PHP_FPM_SOCK};
                        include fastcgi_params;
                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                }
                location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))\$ {
                        root /home/${USERNAME};
                }
        }

        # laravel
        root /home/${USERNAME}/public_html/${PROJECT_DIRECTORY}/prod/public;
        index index.php index.html index.htm;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
        #       # With php7.0-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
        #       # With php7.0-fpm:
                fastcgi_pass unix:${PHP_FPM_SOCK};
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }

        access_log /var/log/nginx/${DOMAIN_NAME}.access.log;
        error_log /var/log/nginx/${DOMAIN_NAME}.error.log;
}

${CERT_UNCOMMENT}server {
${CERT_UNCOMMENT}        listen 80;
${CERT_UNCOMMENT}        server_name ${DOMAIN_NAME};
${CERT_UNCOMMENT}        error_log   /dev/null   crit;
${CERT_UNCOMMENT}        access_log off;
${CERT_UNCOMMENT}        location / {
${CERT_UNCOMMENT}                return 301 https://\$host\$request_uri;
${CERT_UNCOMMENT}        }
${CERT_UNCOMMENT}}

# server for redirecting from IP to DNS
server {
        listen 80;
        listen 443;
        error_log   /dev/null   crit;
        access_log off;
        server_name ${SERVER_IP};
        return 301 http://${DOMAIN_NAME}/\$request_uri;
}
EOF

cat <<EOF > ${NGINX_SITEAVAILABLE_DIR}/dev.${DOMAIN_NAME}.conf
server {
        listen 80;
        ${CERT_COMMENT}listen 443 ssl http2;
        server_name dev.${DOMAIN_NAME};

        ${CERT_COMMENT}ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
        ${CERT_COMMENT}ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;
        ${CERT_COMMENT}include /etc/letsencrypt/options-ssl-nginx.conf;
        ${CERT_COMMENT}ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

        ${CERT_COMMENT}ssl_stapling on;
        ${CERT_COMMENT}ssl_stapling_verify on;
        ${CERT_COMMENT}ssl_trusted_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
        resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 valid=3600s;
        resolver_timeout 5s;

        client_max_body_size ${NGINX_MAX_BODY_SIZE};

        # phpmyadmin
        location /phpmyadmin {
                auth_basic "Restricted Content";
                auth_basic_user_file /home/${USERNAME}/.htpasswd;

                root /home/${USERNAME};
                index index.php index.html index.htm;
                location ~ ^/phpmyadmin/(.+\.php)\$ {
                        try_files \$uri \$uri/ =404;
                        fastcgi_pass unix:${PHP_FPM_SOCK};
                        include fastcgi_params;
                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                }
                location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))\$ {
                        root /home/${USERNAME};
                }
        }

        # laravel
        root /home/${USERNAME}/public_html/${PROJECT_DIRECTORY}/dev/public;
        index index.php index.html index.htm;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
        #       # With php7.0-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
        #       # With php7.0-fpm:
                fastcgi_pass unix:${PHP_FPM_SOCK};
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }

        access_log /var/log/nginx/dev.${DOMAIN_NAME}.access.log;
        error_log /var/log/nginx/dev.${DOMAIN_NAME}.error.log;
}

${CERT_UNCOMMENT}server {
${CERT_UNCOMMENT}        listen 80;
${CERT_UNCOMMENT}        server_name dev.${DOMAIN_NAME};
${CERT_UNCOMMENT}        error_log   /dev/null   crit;
${CERT_UNCOMMENT}        access_log off;
${CERT_UNCOMMENT}        location / {
${CERT_UNCOMMENT}                return 301 https://\$host\$request_uri;
${CERT_UNCOMMENT}        }
${CERT_UNCOMMENT}}
EOF

cat <<EOF > ${NGINX_SITEAVAILABLE_DIR}/staging.${DOMAIN_NAME}.conf
server {
        listen 80;
        ${CERT_COMMENT}listen 443 ssl http2;
        server_name staging.${DOMAIN_NAME};

        ${CERT_COMMENT}ssl_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;
        ${CERT_COMMENT}ssl_certificate_key /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem;
        ${CERT_COMMENT}include /etc/letsencrypt/options-ssl-nginx.conf;
        ${CERT_COMMENT}ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

        ${CERT_COMMENT}ssl_stapling on;
        ${CERT_COMMENT}ssl_stapling_verify on;
        ${CERT_COMMENT}ssl_trusted_certificate /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem;

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
        resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 valid=3600s;
        resolver_timeout 5s;

        client_max_body_size ${NGINX_MAX_BODY_SIZE};

        # phpmyadmin
        location /phpmyadmin {
                auth_basic "Restricted Content";
                auth_basic_user_file /home/${USERNAME}/.htpasswd;

                root /home/${USERNAME};
                index index.php index.html index.htm;
                location ~ ^/phpmyadmin/(.+\.php)\$ {
                        try_files \$uri \$uri/ =404;
                        fastcgi_pass unix:${PHP_FPM_SOCK};
                        include fastcgi_params;
                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                }
                location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))\$ {
                        root /home/${USERNAME};
                }
        }

        # laravel
        root /home/${USERNAME}/public_html/${PROJECT_DIRECTORY}/staging/public;
        index index.php index.html index.htm;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
        #       # With php7.0-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
        #       # With php7.0-fpm:
                fastcgi_pass unix:${PHP_FPM_SOCK};
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        location ~ /\.ht {
                deny all;
        }

        access_log /var/log/nginx/staging.${DOMAIN_NAME}.access.log;
        error_log /var/log/nginx/staging.${DOMAIN_NAME}.error.log;
}

${CERT_UNCOMMENT}server {
${CERT_UNCOMMENT}        listen 80;
${CERT_UNCOMMENT}        server_name staging.${DOMAIN_NAME};
${CERT_UNCOMMENT}        error_log   /dev/null   crit;
${CERT_UNCOMMENT}        access_log off;
${CERT_UNCOMMENT}        location / {
${CERT_UNCOMMENT}                return 301 https://\$host\$request_uri;
${CERT_UNCOMMENT}        }
${CERT_UNCOMMENT}}
EOF

ln -sf ${NGINX_SITEAVAILABLE_DIR}/${DOMAIN_NAME}.conf ${NGINX_SITEENABLE_DIR}/${DOMAIN_NAME}.conf >> ${LOG_FILE} 2>&1
check_cmd_status "link enable nginx config prod.."

ln -sf ${NGINX_SITEAVAILABLE_DIR}/dev.${DOMAIN_NAME}.conf ${NGINX_SITEENABLE_DIR}/dev.${DOMAIN_NAME}.conf >> ${LOG_FILE} 2>&1
check_cmd_status "link enable nginx config dev.."

ln -sf ${NGINX_SITEAVAILABLE_DIR}/staging.${DOMAIN_NAME}.conf ${NGINX_SITEENABLE_DIR}/staging.${DOMAIN_NAME}.conf >> ${LOG_FILE} 2>&1
check_cmd_status "link enable nginx config staging.."

nginx -t >> ${LOG_FILE} 2>&1
check_cmd_status "test nginx config.."

systemctl reload nginx >> ${LOG_FILE} 2>&1
check_cmd_status "reload nginx service.."


# Add MySQL user
echo -e "${GREEN}[*]${RESET} Create MySQL user and database.."

SQL_QUERY="CREATE USER IF NOT EXISTS 'prod_${USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_PROD_PASSWORD}';
CREATE DATABASE IF NOT EXISTS prod_${USERNAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON prod_${USERNAME}.* TO 'prod_${USERNAME}'@'localhost';
FLUSH PRIVILEGES;"

mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "${SQL_QUERY}" >> ${LOG_FILE} 2>&1
check_cmd_status "create user and database production.."

SQL_QUERY="CREATE USER IF NOT EXISTS 'dev_${USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_DEV_PASSWORD}';
CREATE DATABASE IF NOT EXISTS dev_${USERNAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON dev_${USERNAME}.* TO 'dev_${USERNAME}'@'localhost';
FLUSH PRIVILEGES;"

mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "${SQL_QUERY}" >> ${LOG_FILE} 2>&1
check_cmd_status "create user and database development.."

SQL_QUERY="CREATE USER IF NOT EXISTS 'staging_${USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_STAGING_PASSWORD}';
CREATE DATABASE IF NOT EXISTS staging_${USERNAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON staging_${USERNAME}.* TO 'staging_${USERNAME}'@'localhost';
FLUSH PRIVILEGES;"

mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "${SQL_QUERY}" >> ${LOG_FILE} 2>&1
check_cmd_status "create user and database staging.."


# Config supervisord
echo -e "${GREEN}[*]${RESET} Configure supervisor.."

groupadd -f supervisor >> ${LOG_FILE} 2>&1
check_cmd_status "add group supervisor.."

usermod -aG supervisor root; usermod -aG supervisor ${USERNAME} >> ${LOG_FILE} 2>&1
check_cmd_status "add user to supervisor group.."

chown root:supervisor /var/run/supervisor.sock >> ${LOG_FILE} 2>&1
check_cmd_status "change owner supervisor sock.."

sed -i 's/chmod=0700/chown=root:supervisor\nchmod=0770/g' /etc/supervisor/supervisord.conf >> ${LOG_FILE} 2>&1
check_cmd_status "edit supervisor config.."

mkdir -p /home/${USERNAME}/supervisord.d >> ${LOG_FILE} 2>&1
check_cmd_status "add supervisord.d config directory for user.."

cat <<EOF > /home/${USERNAME}/supervisord.d/sample-worker.bak
[program:domain-name-worker]
command=php /home/${USERNAME}/public_html/project_folder/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
redirect_stderr=true
stderr_logfile = /home/${USERNAME}/public_html/project_folder/storage/logs/stderr.log
#stdout_logfile = /home/${USERNAME}/public_html/project_folder/storage/logs/stdout.log
EOF

chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/supervisord.d >> ${LOG_FILE} 2>&1
check_cmd_status "change owner to user.."

sed -i 's#^files = /etc/supervisor/conf\.d/\*\.conf$#files = /etc/supervisor/conf\.d/\*\.conf /home/'"${USERNAME}"'/supervisord\.d/\*\.conf#g' /etc/supervisor/supervisord.conf >> ${LOG_FILE} 2>&1
check_cmd_status "include user supervisord.d config.."

systemctl restart supervisor >> ${LOG_FILE} 2>&1
check_cmd_status "restart supervisor.."


# install nodejs & npm
echo -e "${GREEN}[*]${RESET} Install NodeJS & NPM.."

curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash >> ${LOG_FILE} 2>&1
check_cmd_status "install nodejs & npm.."

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

source ~/.bashrc >> ${LOG_FILE} 2>&1
check_cmd_status "reload bashrc.."

nvm install ${NODE_VERSION} >> ${LOG_FILE} 2>&1
check_cmd_status "install nodejs & npm.."

cp -rf $NVM_DIR /home/${USERNAME}/.nvm >> ${LOG_FILE} 2>&1
check_cmd_status "copy nvm to user.."

chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.nvm >> ${LOG_FILE} 2>&1
check_cmd_status "change owner nvm to user.."

if ! grep -q "export NVM_DIR=" /home/${USERNAME}/.bashrc; then
cat <<EOF >> /home/${USERNAME}/.bashrc
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
fi


# Config redist
echo -e "${GREEN}[*]${RESET} Configure redis cache.."

sed -i 's/# maxmemory <bytes>/maxmemory '"${REDIS_MAX_MEMORY}"'/g' /etc/redis/redis.conf >> ${LOG_FILE} 2>&1
check_cmd_status "set redis maxmemory.."

sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/g' /etc/redis/redis.conf >> ${LOG_FILE} 2>&1
check_cmd_status "set redis maxmemory-policy.."

systemctl restart redis-server >> ${LOG_FILE} 2>&1
check_cmd_status "restart redis service.."


echo -e "${GREEN}[*]${RESET} DONE."
echo -e "\n"

# Show All Credentials
echo -e "${GREEN}=================== CREDENTIALS ===================${RESET}"
echo -e ""
echo -e "[SSH/SFTP]"
echo -e "  SERVERIP: ${SERVER_IP}"
echo -e "  PORT: 22"
echo -e "  USERNAME: ${USERNAME}"
echo -e "  PASSWORD: ${PASSWORD}"
echo -e ""
echo -e "[MySQL]"
echo -e "  SERVERIP: ${SERVER_IP}"
echo -e "  PORT: 3306"
echo -e "  [root]"
echo -e "    USERNAME: root"
echo -e "    PASSWORD: ${MYSQL_ROOT_PASSWORD}"
echo -e "  [PRODUCTION]"
echo -e "    DATABASENAME: prod_${USERNAME}"
echo -e "    USERNAME: prod_${USERNAME}"
echo -e "    PASSWORD: ${MYSQL_PROD_PASSWORD}"
echo -e "  [STAGING]"
echo -e "    DATABASENAME: staging_${USERNAME}"
echo -e "    USERNAME: staging_${USERNAME}"
echo -e "    PASSWORD: ${MYSQL_STAGING_PASSWORD}"
echo -e "  [DEVELOPMENT]"
echo -e "    DATABASENAME: dev_${USERNAME}"
echo -e "    USERNAME: dev_${USERNAME}"
echo -e "    PASSWORD: ${MYSQL_DEV_PASSWORD}"
echo -e ""
echo -e "[phpMyAdmin]"
echo -e "  URL: https://${DOMAIN_NAME}/phpmyadmin"
echo -e "  [BasicAuth]"
echo -e "    USERNAME: ${USERNAME}"
echo -e "    PASSWORD: ${PASSWORD}"
echo -e ""
echo -e "[Website]"
echo -e "  [PRODUCTION]"
echo -e "    URL: https://${DOMAIN_NAME}/"
if [[ STAGING_DOMAIN_IP == SERVER_IP ]]; then
echo -e "  [STAGING]"
echo -e "    URL: https://staging.${DOMAIN_NAME}/"
fi
if [[ DEV_DOMAIN_IP == $SERVER_IP ]]; then
echo -e "  [DEVELOPMENT]"
echo -e "    URL: https://dev.${DOMAIN_NAME}/"
fi
echo -e "${GREEN}====================================================${RESET}"
