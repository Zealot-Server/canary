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

CMD ["apache2-foreground"]
