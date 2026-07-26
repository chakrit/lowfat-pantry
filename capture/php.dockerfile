# composer — the official installer script, no separate composer image.
FROM php:8-cli-alpine

RUN curl -fsSL https://getcomposer.org/installer -o /tmp/installer.php \
    && php /tmp/installer.php --install-dir=/usr/local/bin --filename=composer \
    && rm /tmp/installer.php
