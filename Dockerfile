FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive

ENV APP_ENV='prod'
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY ./ /var/www/koillection

# Instalação de dependências
RUN apt-get update && \
    apt-get install -y curl wget lsb-release software-properties-common gnupg2 && \
    add-apt-repository ppa:ondrej/php && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    NODE_MAJOR=21 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y \
    libnss3 \
    nss-plugin-pem \
    ca-certificates \
    apt-transport-https \
    git \
    unzip \
    nginx-light \
    openssl \
    php8.4 \
    php8.4-apcu \
    php8.4-curl \
    php8.4-pgsql \
    php8.4-mysql \
    php8.4-mbstring \
    php8.4-gd \
    php8.4-xml \
    php8.4-zip \
    php8.4-fpm \
    php8.4-intl \
    nodejs

# Instalação do Composer e dependências PHP
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cd /var/www/koillection && \
    composer install --classmap-authoritative
