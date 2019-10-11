# ubuntu:latest at 2019-02-12T19:22:56IST
FROM php:7.2-cli

RUN echo "tzdata tzdata/Areas select America" | debconf-set-selections && \
echo "tzdata tzdata/Zones/Asia select New_York" | debconf-set-selections

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    curl \
    git \
    gosu \
    jq \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    meson \
    mime-support \
    nodejs \
    npm \
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

ENV NVM_DIR /usr/local/nvm

RUN useradd -m -s /bin/bash tr1b0t

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
&& curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
# Make sure we're installing what we think we're installing!
&& php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
&& php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --snapshot \
&& rm -f /tmp/composer-setup.*

# via: https://tecadmin.net/mount-s3-bucket-centosrhel-ubuntu-using-s3fs/
RUN cd /usr/src/ \
&& wget https://github.com/libfuse/libfuse/releases/download/fuse-3.5.0/fuse-3.5.0.tar.xz \
&& tar Jxf fuse-3.5.0.tar.xz \
&& cd fuse-3.5.0 \
&& mkdir build \
&& cd build \
&& meson .. \
&& export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
&& ldconfig \
&& modprobe fuse

RUN cd /usr/src/ \
&& git clone https://github.com/s3fs-fuse/s3fs-fuse.git \
&& cd s3fs-fuse \
&& ./autogen.sh \
&& ./configure \
&& make && make install

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
