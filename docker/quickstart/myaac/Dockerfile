FROM php:8.3-apache

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		libicu-dev \
		libpng-dev \
		libzip-dev \
		python3 \
	&& docker-php-ext-install -j"$(nproc)" gd intl mysqli opcache pdo_mysql zip \
	&& a2enmod headers rewrite \
	&& rm -rf /var/lib/apt/lists/*

COPY quickstart/myaac/entrypoint.sh /usr/local/bin/myaac-quickstart
COPY quickstart/myaac/disable-legacy-login.conf /etc/apache2/conf-available/disable-legacy-login.conf

RUN chmod 0755 /usr/local/bin/myaac-quickstart \
	&& a2enconf disable-legacy-login

CMD ["apache2-foreground"]
