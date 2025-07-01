#!/bin/sh
set -e

echo "**** Migrating database (if needed) ****"
cd /var/www/koillection
php bin/console doctrine:migration:migrate --no-interaction --allow-no-migration

echo "**** Creating API keys (if needed) ****"
php bin/console lexik:jwt:generate-keypair --skip-if-exists

echo "**** Setup complete, starting supervisord... ****"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
