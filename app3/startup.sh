#!/usr/bin/env bash
# startup.sh — App Service Linux PHP does not ship the SQL Server driver.
# Set this as the app's "Startup Command" so the driver is
# installed when the container starts, then Apache is launched normally.
set -e

if ! php -m | grep -qi pdo_sqlsrv; then
    apt-get update
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        gnupg2 unixodbc-dev
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    echo "deb [signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
        > /etc/apt/sources.list.d/mssql-release.list
    apt-get update
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18
    pecl install sqlsrv pdo_sqlsrv
    docker-php-ext-enable sqlsrv pdo_sqlsrv
fi

apache2-foreground
