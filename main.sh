#!/bin/bash

## log functions

function logWarn() {
	START='\033[01;33m'
	END='\033[00;00m'
	MESSAGE=${@:-""}
	echo -e "${START}${MESSAGE}${END}"
}

function logInfo() {
	START='\033[01;32m'
	END='\033[00;00m'
	MESSAGE=${@:-""}
	echo -e "${START}${MESSAGE}${END}"
}

function logError() {
	START='\033[01;31m'
	END='\033[00;00m'
	MESSAGE=${@:-""}
	echo -e "${START}${MESSAGE}${END}"
}

function log() {
        MESSAGE=${@:-""}
        echo -e "${MESSAGE}"
}

## read functions

function getVarFromFile() {
    local filePath=$1

    if [ ! -f $filePath ]; then
        logError "No existe el fichero $filePath en getVarFromFile"
        exit 1
    fi

    echo $(cat $filePath);
}

###################################

## variables to source
temp_vars_dir="temp_vars";
magento_version_temp_file_path="$temp_vars_dir/magento_version_temp_file";

function createMagentoVersionTempFile() {
    if [ ! -f $magento_version_temp_file_path ]; then
        log "Elige versión de magento:";

        versiones="2.4.1 2.4.2";

        select version in $versiones
        do
            if [ $version = "2.4.1" ]; then
                log "2.4.1";
            elif [ $version = "2.4.2" ]; then
                log "2.4.2";
            else
                exit;
            fi
            
            touch $magento_version_temp_file_path;
            echo $version > "$magento_version_temp_file_path";
            exit;
        done
    fi
}
createMagentoVersionTempFile




# log "Ejemplo de Menu de Opciones."
# logInfo "Opción Seleccionada 1 !";
# logError "Finaliza la Ejecución. !";
# logWarn "Seleccione una Opción de 1 a 5.";