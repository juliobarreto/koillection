FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive

# ENV APP_ENV é útil, mas PUID/PGID/USER são removidos
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
    composer install --classmap-authoritative --no-dev --optimize-autoloader && \
    composer clearcache

# Build dos assets Javascript
RUN cd /var/www/koillection/ && \
    php bin/console app:translations:dump && \
    corepack enable && \
    cd /var/www/koillection/assets && \
    yarn install && \
    yarn build

# Limpeza
RUN apt-get purge -y wget lsb-release software-properties-common git nodejs apt-transport-https, ca-certificates gnupg2 unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/bin/composer && \
    rm -rf /var/www/koillection/assets/node_modules && \
    rm -rf /var/www/koillection/assets/.yarn

# Configuração do Nginx e PHP
RUN cp /var/www/koillection/docker/default.conf /etc/nginx/nginx.conf && \
    cp /var/www/koillection/docker/php.ini /etc/php/8.4/fpm/conf.d/php.ini && \
    mkdir -p /run/php

# Instalação do curl-impersonate
ADD https://github.com/lwthiker/curl-impersonate/releases/download/v0.6.1/libcurl-impersonate-v0.6.1.x86_64-linux-gnu.tar.gz /opt/
RUN cd /opt && tar xvzf libcurl-impersonate-v0.6.1.x86_64-linux-gnu.tar.gz && rm libcurl-impersonate-v0.6.1.x86_64-linux-gnu.tar.gz

# --- CORREÇÃO FINAL DE PERMISSÕES PARA O OPENSHIFT ---
# Garante que os diretórios necessários possam ser escritos pelo usuário do OpenShift
RUN chown -R root:0 /var/www/koillection /run/php /var/lib/nginx /etc/nginx/conf.d && \
    chmod -R g+w /var/www/koillection /run/php /var/lib/nginx /etc/nginx/conf.d && \
    chmod +x /var/www/koillection/docker/entrypoint.sh

EXPOSE 80

WORKDIR /var/www/koillection

ENTRYPOINT ["sh", "/var/www/koillection/docker/entrypoint.sh" ]
