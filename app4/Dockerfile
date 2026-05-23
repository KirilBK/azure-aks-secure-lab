# app4 Dockerfile — minimal, non-root, single small image. (exam T208)
FROM php:8.2-apache

RUN sed -ri 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf \
    && sed -ri 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf

COPY index.php /var/www/html/index.php
RUN chown -R www-data:www-data /var/www/html

USER www-data
EXPOSE 8080
