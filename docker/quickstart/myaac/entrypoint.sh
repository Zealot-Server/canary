#!/bin/sh

set -eu

server_path="${MYAAC_SERVER_PATH%/}"
attempt=1
while [ ! -r "${server_path}/config.lua" ]; do
	if [ "$attempt" -ge 90 ]; then
		echo "Canary config.lua did not become available at ${server_path}/config.lua" >&2
		exit 1
	fi

	echo "Waiting for Canary config.lua (attempt ${attempt}/90)"
	attempt=$((attempt + 1))
	sleep 2
done

php /canary/docker/quickstart/myaac/bootstrap.php

mkdir -p \
	/var/www/html/system/cache/twig \
	/var/www/html/system/logs \
	/var/www/html/system/php_sessions \
	/var/www/html/images/items \
	/var/www/html/images/library/market-outfits \
	/var/www/html/images/library/daily-boost

chown -R www-data:www-data \
	/var/www/html/system/cache \
	/var/www/html/system/logs \
	/var/www/html/system/php_sessions \
	/var/www/html/images/items \
	/var/www/html/images/library/market-outfits \
	/var/www/html/images/library/daily-boost

runuser -u www-data -- sh -c '
	while true; do
		php /var/www/html/system/bin/sync_daily_boost_sprites.php --if-missing >&2 || true
		sleep 300
	done
' &

exec apache2-foreground
