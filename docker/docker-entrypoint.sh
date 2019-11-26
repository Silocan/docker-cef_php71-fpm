#!/bin/bash
set -e

if [ "$USER" = "root" ]; then

    # set localtime
    ln -sf /usr/share/zoneinfo/$LOCALTIME /etc/localtime

    # secure path
    chmod a-rwx -R $PHP_INI_DIR/ /etc/ssmtp
fi

#
# functions

function set_conf {
    echo ''>$2; IFSO=$IFS; IFS=$(echo -en "\n\b")
    for c in `printenv|grep $1`; do echo "`echo $c|cut -d "=" -f1|awk -F"$1" '{print $2}'` $3 `echo $c|cut -d "=" -f2`" >> $2; done;
    IFS=$IFSO
}

#
# PHP

echo "date.timezone = \"${LOCALTIME}\"" >> $PHP_INI_DIR/conf.d/00-default.ini
if [ "$PHP_php5enmod" != "" ]; then docker-php-ext-enable $PHP_php5enmod > /dev/null 2>&1; fi;
set_conf "PHP__" "$PHP_INI_DIR/conf.d/40-user.ini" "="

# Set ssmtp server
if [ -n "$SMTP" ]; then
    echo 'sendmail_path = /usr/sbin/ssmtp -t' >> $PHP_INI_DIR/conf.d/00-default.ini
    sed -i "s/mailhub=.*/mailhub=${SMTP}/"  /etc/ssmtp/ssmtp.conf
fi

#
# Run

# Install composer

if [[ -f /var/www/composer.json ]]; then
    cd /var/www
    composer install --prefer-dist --no-progress --no-suggest --no-interaction --no-plugins --no-dev
    composer dump-autoload -o
    #bin/console doctrine:database:create  --no-interaction
    #bin/console doctrine:migration:migrate  --allow-no-migration --no-interaction
fi

chmod 777 -Rf /var/www


exec "$@"
