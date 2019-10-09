# ubuntu:latest at 2019-02-12T19:22:56IST
FROM php:7.2-cli

RUN echo "tzdata tzdata/Areas select America" | debconf-set-selections && \
echo "tzdata tzdata/Zones/Asia select New_York" | debconf-set-selections

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    gosu \
    jq \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    rsync \
    sudo \
    tree \
    zip \
    unzip \
    wget ; \
    rm -rf /var/lib/apt/lists/*; \
    # verify that the binary works
    gosu nobody true \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) zip

RUN useradd -m -s /bin/bash tr1b0t

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
&& curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
# Make sure we're installing what we think we're installing!
&& php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
&& rm -f /tmp/composer-setup.*
