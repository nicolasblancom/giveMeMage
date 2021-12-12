#! /bin/bash

##
##
## This script does all necessary steps to have a fully functional Magento 2 instance
## Creates database, downloads Magento 2 specified version using composer, installs it and
## prepares Magento for development enviroment (developer mode, grunt enabled, spanish
## language pack installed, 2FA module disabled)
##
##

##
## String with ##string_here## will be replaced
##

function create_database {
    mysql -h mysql -u root --password='' -e "DROP DATABASE IF EXISTS \`##project_name##\`;"
    mysql -h mysql -u root --password='' -e "CREATE DATABASE \`##project_name##\`;"
    
    # parece que no hace falta darle permisos
    echo
    echo "-- database '##project_name##' created"
    echo
}
create_database

# copy auth.json (avoid entering manually composer magento repo credentials)
function copy_auth_json {

    composer_dir=/home/devilbox/.composer

    if [ ! -d "$composer_dir" ]; then 
        mkdir "$composer_dir"
    fi

    cp ./auth.json "$composer_dir/auth.json"

    ## TODO: copy auth.json to src root too

    echo
    echo "-- auth.json copied into $composer_dir"
    echo
}
copy_auth_json

# download magento with magento_version
function download_magento {
    /usr/local/bin/composer-1 create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=##magento_version## ./htdocs
}
download_magento

# set file permissions
function set_permissions {
    ## TODO check if not in this directory first
    
    cd htdocs
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
    # chown -R :devilbox .
    chmod u+x bin/magento

    echo
    echo "-- set correct permissions to htdocs files"
    echo
}
set_permissions

# run magento installation
function install_magento {
    ## TODO: already moved in previous function call, check if not in this directory first
    # cd htdocs

    php -d memory_limit=-1 bin/magento setup:install \
    --base-url=http://##project_name##.loc/ \
    --db-host=127.0.0.1 \
    --db-name=##project_name## \
    --db-user=root \
    --admin-firstname=admin \
    --admin-lastname=admin \
    --admin-email=admin@admin.com \
    --admin-user=admin \
    --admin-password=g9egcwUE6WEGsyw98kKB4hu \
    --language=en_US \
    --currency=EUR \
    --timezone=Europe/Madrid \
    --use-rewrites=1 \
    --search-engine=elasticsearch7 \
    --elasticsearch-host=172.16.238.240 \
    --elasticsearch-port=9200
}
install_magento

# run post installation steps
function post_install_steps {
    ## TODO: check if not in this directory first
    ## cd htdocs

    # install Pestle
    curl -LO http://pestle.pulsestorm.net/pestle.phar
    chmod +x pestle.phar

    # disable magento modules
    php bin/magento module:disable Magento_TwoFactorAuth

    # install mageplaza es_ES language pack
    if [ ! -d /home/devilbox/.composer ]; then
        copy_auth_json
    fi
    /usr/local/bin/composer-1 require --no-update mageplaza/magento-2-spanish-language-pack:dev-master

    # TODO: Install mageplaza smtp. Assign temporary key directly from db

    # enable grunt for local developemnt
    cp Gruntfile.js.sample Gruntfile.js
    cp package.json.sample package.json
    cp grunt-config.json.sample grunt-config.json
    cp dev/tools/grunt/configs/themes.js dev/tools/grunt/configs/local-themes.js
    npm install
    npm update

    ## TODO: create .gitignore
}
post_install_steps

# finish install and leave it prepare for work
function finish_installation {
    php bin/magento deploy:mode:set developer

    rm -rf var/cache/* var/page_cache/* var/view_preprocessed/* pub/static/* generated/* 

    php bin/magento setup:upgrade

    php bin/magento setup:di:compile

    php bin/magento setup:static-content:deploy -f
}
finish_installation