FROM php:7.3-alpine

# docker-entrypoint.sh dependencies
RUN apk add --no-cache \
	# in theory, docker-entrypoint.sh is POSIX-compliant, but priority is a working, consistent image
	bash \
	# BusyBox sed is not sufficient for some of our sed expressions
	sed

# install the PHP extensions we need
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
	libjpeg-turbo-dev \
	libpng-dev \
	libzip-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache zip; \
	\
	runDeps="$( \
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
	| tr ',' '\n' \
	| sort -u \
	| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
	echo 'opcache.memory_consumption=128'; \
	echo 'opcache.interned_strings_buffer=8'; \
	echo 'opcache.max_accelerated_files=4000'; \
	echo 'opcache.revalidate_freq=2'; \
	echo 'opcache.fast_shutdown=1'; \
	echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
#upload
RUN { \
	echo "file_uploads=On"; \
	echo "memory_limit=500M"; \
	echo "upload_max_filesize=500M"; \
	echo "post_max_size=500M";  \
	echo "max_execution_time=600"; \
	} > /usr/local/etc/php/conf.d/uploads.ini

VOLUME /var/www/html

ENV WORDPRESS_VERSION 5.0.3
ENV WORDPRESS_SHA1 f9a4b482288b5be7a71e9f3dc9b5b0c1f881102b

RUN set -ex; \
	curl -LO https://wordpress.org/latest.zip; \
	# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	unzip latest.zip -d /usr/src/; \
	rm latest.zip; \
	curl -LO https://downloads.wordpress.org/plugin/sqlite-integration.1.8.1.zip; \
	unzip sqlite-integration.1.8.1.zip -d /usr/src/wordpress/wp-content/plugins/; \
	cp /usr/src/wordpress/wp-content/plugins/sqlite-integration/db.php /usr/src/wordpress/wp-content; \
	chown -R www-data:www-data /usr/src/wordpress
