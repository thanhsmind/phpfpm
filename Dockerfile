FROM php:7.4.2-fpm-alpine3.11

ARG PHP_VERSION=7.4.2

ARG WORKDIRECTORY=/app

ARG HOST_USER_UID=1000
ARG HOST_USER_GID=1000
ARG HOST_USER_NAME=www
ARG HOST_GROUP_NAME=www


RUN set -xe \
&& apk add --no-cache git ssmtp \
&& echo 'Creating notroot user and group from host' \
&& addgroup -g ${HOST_USER_GID} -S ${HOST_GROUP_NAME} \
&& adduser  -u ${HOST_USER_UID} -D -S -G ${HOST_GROUP_NAME} ${HOST_USER_NAME} \
\
&& apk add --no-cache --virtual .build-deps \
$PHPIZE_DEPS \
icu-dev \
postgresql-dev \
zlib-dev \
jpeg-dev \
libpng-dev \
libmemcached-dev \
pcre-dev \
freetype-dev \
libxml2-dev \
\
&& docker-php-ext-install -j$(nproc) \
pdo \
pdo_mysql \
xml \
json \
intl \
opcache \
mbstring \
zip \
\
&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
&& docker-php-ext-install -j$(nproc) gd	 \
&& docker-php-ext-enable gd \
\
&& pecl install \
apcu \
xdebug \
memcached \
redis \
oauth \
mongodb \
&& docker-php-ext-enable \
apcu \
xdebug \
memcached \
redis \
oauth \
mongodb \
\
&& apk add --no-cache imagemagick imagemagick-dev \
&& pecl install imagick \
&& docker-php-ext-enable imagick \
\
&& runDeps="$( \
scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
| tr ',' '\n' \
| sort -u \
| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
)" \
&& apk add --no-cache --virtual .api-phpexts-rundeps $runDeps \
&& apk del .build-deps \
\
&& mkdir -p var/cache var/logs var/sessions \
&& sed -e "s/user\s*=.*/user = ${HOST_USER_NAME}/"  -i /usr/local/etc/php-fpm.d/www.conf \
&& sed -e "s/group\s*=.*/group = ${HOST_GROUP_NAME}/"  -i /usr/local/etc/php-fpm.d/www.conf


ADD https://raw.githubusercontent.com/php/php-src/php-${PHP_VERSION}/php.ini-production /usr/local/etc/php/php.ini
ADD https://curl.haxx.se/ca/cacert.pem /usr/local/etc/php/cacert.pem.txt

RUN chmod 664 /usr/local/etc/php/cacert.pem.txt

RUN set -xe \
&& echo "Modify php.ini config" \
&& sed -e "s/^short_open_tag .*$/short_open_tag = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^asp_tags .*$/asp_tags = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^expose_php .*$/expose_php = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^display_errors .*$/display_errors = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^display_startup_errors .*$/display_startup_errors = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^log_errors .*$/log_errors = On/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^memory_limit .*$/memory_limit = 150M/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^allow_url_fopen .*$/allow_url_fopen = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^allow_url_include .*$/allow_url_include = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;date\.timezone .*$/date\.timezone = \"Asia\/Ho_Chi_Minh\"/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^safe_mode .*$/safe_mode = Off/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^disable_functions .*$/disable_functions = proc_open, popen, disk_free_space, diskfreespace, leak, system, shell_exec, escapeshellcmd, proc_nice, dl, symlink, show_source/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^max_execution_time .*$/max_execution_time = 60/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^max_execution_time .*$/max_execution_time = 60/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;opcache\.enable.*$/opcache.enable = 1/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;opcache\.enable_cli.*$/opcache.enable_cli = 1/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;opcache\.validate_timestamps.*$/opcache.validate_timestamps = 1/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;opcache\.revalidate_freq.*$/opcache.revalidate_freq = 1/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;curl\.cainfo.*$/curl\.cainfo = \/usr\/local\/etc\/php\/cacert\.pem\.txt/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^\;openssl\.cafile.*$/openssl\.cafile = \/usr\/local\/etc\/php\/cacert\.pem\.txt/g" -i /usr/local/etc/php/php.ini \
&& sed -e "s/^mailhub.*$/mailhub=mail:1025/g" -i /etc/ssmtp/ssmtp.conf

VOLUME ["${WORKDIRECTORY}"]

WORKDIR ${WORKDIRECTORY}
