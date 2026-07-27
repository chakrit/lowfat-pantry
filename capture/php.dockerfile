# composer — php from the alpine repos, composer from its official installer.
# phar/openssl/mbstring are composer's own requirements, not php's.
FROM lowfat-capture-base

RUN apk add --no-cache php83 php83-phar php83-openssl php83-mbstring php83-iconv \
    && ln -s /usr/bin/php83 /usr/bin/php \
    && curl -fsSL https://getcomposer.org/installer -o /tmp/installer.php \
    && php /tmp/installer.php --install-dir=/usr/local/bin --filename=composer \
    && rm /tmp/installer.php
