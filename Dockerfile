FROM php:7.2-cli
MAINTAINER Rich Hildred <rhildred@gmail.com>

# Install Curl
RUN apt-get update && apt-get install -yy \
      curl \
      git \
      unzip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LO https://wordpress.org/latest.zip \
    && unzip latest.zip \
    && curl -LO https://downloads.wordpress.org/plugin/sqlite-integration.1.8.1.zip \
    && unzip sqlite-integration.1.8.1.zip -d /wordpress/wp-content/plugins/ \
    && cp /wordpress/wp-content/plugins/sqlite-integration/db.php /wordpress/wp-content \
    && mv /wordpress/wp-config-sample.php /wordpress/wp-config.php \
    && rm *zip
