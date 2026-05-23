# app1 Dockerfile — multi-stage, non-root, slim. (exam T202)
#
# Hardening vs. a single-stage exam build:
#   - SQL Server PHP extensions compiled in a builder layer; final image keeps
#     only the runtime ODBC driver + app code (no build toolchain).
#   - Apache listens on unprivileged port 8080 and runs as www-data (uid 33),
#     matching the restricted securityContext in deployment.yaml.
#   - /var/run/apache2, /var/log/apache2 and /tmp are provided as writable
#     emptyDir mounts at runtime so the container can keep a read-only root fs.

# ---- builder: compile the SQL Server PHP extensions ----
FROM php:8.3-apache AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg2 curl apt-transport-https unixodbc-dev \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
        > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && rm -rf /var/lib/apt/lists/*

# ---- final ----
FROM php:8.3-apache

# Runtime ODBC driver only.
COPY --from=builder /usr/share/keyrings/microsoft.gpg /usr/share/keyrings/microsoft.gpg
COPY --from=builder /etc/apt/sources.list.d/mssql-release.list /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 unixodbc \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Move Apache to an unprivileged port.
RUN sed -ri 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf \
    && sed -ri 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf

# App code + a DB-free liveness endpoint.
COPY web/ /var/www/html/
RUN echo '<?php http_response_code(200); echo "ok";' > /var/www/html/healthz.php \
    && chown -R www-data:www-data /var/www/html

USER www-data
EXPOSE 8080
