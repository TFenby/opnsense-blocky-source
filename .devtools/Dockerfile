FROM php:8.2-cli

# Install system dependencies (including gettext for OPNsense i18n and build tools for Phalcon)
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libpcre2-dev \
    gettext \
    && docker-php-ext-install gettext \
    && rm -rf /var/lib/apt/lists/*

# Install Phalcon extension by compiling from source
# Pre-built binaries have ABI mismatches with the official php:8.2-cli Docker image.
# Compiling from source guarantees compatibility.
RUN set -eux; \
    git clone --depth=1 --branch v5.10.0 https://github.com/phalcon/cphalcon.git /tmp/cphalcon; \
    cd /tmp/cphalcon/build; \
    CFLAGS="-Wno-incompatible-pointer-types" ./install; \
    docker-php-ext-enable phalcon; \
    php -m | grep -i phalcon; \
    rm -rf /tmp/cphalcon

# Clone OPNsense core (provides framework classes, layout partials, CSS/JS assets)
RUN git clone --depth=1 --branch master https://github.com/opnsense/core.git /opt/core

# Clone ui_devtools (provides server bootstrap and .htrouter.php routing)
RUN git clone --depth=1 --branch master https://github.com/opnsense/ui_devtools.git /opt/ui_devtools

# Create required ui_devtools working directories and seed config.xml from core sample
RUN mkdir -p /opt/ui_devtools/cache /opt/ui_devtools/temp /opt/ui_devtools/conf \
    && cp /opt/core/src/etc/config.xml.sample /opt/ui_devtools/conf/config.xml

# Copy .htrouter.php to document root (normally done by run_server.php at startup)
RUN cp /opt/ui_devtools/public/.htrouter.php /opt/core/src/opnsense/www/.htrouter.php

WORKDIR /opt/ui_devtools

EXPOSE 8000

# Start PHP built-in server bound to 0.0.0.0 (required for Docker port forwarding)
# run_server.php hardcodes 'localhost' so we bypass it and start the server directly.
# DEV_WORKDIR is required by ui_devtools internals to locate config and routing files.
ENV DEV_WORKDIR=/opt/ui_devtools

CMD ["php", "-d", "open_basedir=", "-S", "0.0.0.0:8000", "-t", "/opt/core/src/opnsense/www", "/opt/core/src/opnsense/www/.htrouter.php"]
