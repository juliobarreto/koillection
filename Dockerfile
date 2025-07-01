FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV COMPOSER_ALLOW_SUPERUSER=1

# Instalação de dependências, incluindo supervisor
RUN apt-get update && \
    apt-get install -y curl wget lsb-release software-properties-common gnupg2 supervisor && \
    add-apt-repository ppa:ondrej/php && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    NODE_MAJOR=21 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y \
    libnss3 nss-plugin-pem ca-certificates apt-transport-https git unzip nginx-light openssl \
    php8.4 php8.4-apcu php8.4-curl php8.4-pgsql php8.4-mysql php8.4-mbstring php8.4-gd \
    php8.4-xml php8.4-zip php8.4-fpm php8.4-intl nodejs

COPY ./ /var/www/koillection

# Instalação do Composer e dependências PHP
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cd /var/www/koillection && \
    composer install --no-scripts --no-autoloader --no-dev && \
    composer dump-autoload --optimize --classmap-authoritative --no-dev && \
    APP_ENV=prod php bin/console cache:clear

# Build dos assets Javascript
RUN cd /var/www/koillection/ && \
    php bin/console app:translations:dump && \
    corepack enable && \
    cd /var/www/koillection/assets && \
    yarn install && \
    yarn build

# Configuração e Permissões para OpenShift
COPY ./docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./docker/default.conf /etc/nginx/nginx.conf
COPY ./docker/php.ini /etc/php/8.4/fpm/conf.d/php.ini

RUN mkdir -p /run/php /uploads /var/log/supervisor && \
    chown -R root:0 /var/www/koillection /run/php /var/lib/nginx /etc/nginx/conf.d /uploads /etc/supervisor /var/log/supervisor && \
    chmod -R g+w /var/www/koillection /run/php /var/lib/nginx /etc/nginx/conf.d /uploads /etc/supervisor /var/log/supervisor && \
    chmod +x /var/www/koillection/docker/entrypoint.sh

# Limpeza Final
RUN rm -rf /var/www/koillection/assets /var/www/koillection/.git && \
    apt-get purge -y wget lsb-release software-properties-common git nodejs apt-transport-https ca-certificates gnupg2 unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/bin/composer

EXPOSE 80
WORKDIR /var/www/koillection
ENTRYPOINT ["/var/www/koillection/docker/entrypoint.sh"]
