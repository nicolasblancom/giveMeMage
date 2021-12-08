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

function listIncludesItem {
    local list="$1"
    local item="$2"

    if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
        # yes, list include item
        return 0
    else
        return 1
    fi

    ## usage 
    # if `listIncludesItem "$tasks" "$task"` ; then
}

###################################

## variables to source
temp_vars_dir="temp_vars";
magento_version_temp_file_path="$temp_vars_dir/magento_version_temp_file";

## functions declarations
function createMagentoVersionTempFileIfNotExists() {
    if [ ! -f $magento_version_temp_file_path ]; then
        local PS3="Elige versión de magento:";

        versiones="2.4.1 2.4.2";

        select version in $versiones
        do
            if [ $version = "2.4.1" ]; then
                log "2.4.1";
                echo 
            elif [ $version = "2.4.2" ]; then
                log "2.4.2";
                echo
            else
                exit;
            fi
            
            touch $magento_version_temp_file_path;
            echo $version > "$magento_version_temp_file_path";
            return
        done
    fi
}

function askToSelectTask() {
    if [ -f $magento_version_temp_file_path ]; then
        local IFS='|'
        local PS3="Elige script a ejecutar:"

        tasks="Preparar local para una v. de magento | Crear nuevo proyecto local "

        select task in $tasks
        do
            if [ $REPLY = 1 ]; then
                log opc 1
                echo
            else
                log otra
                echo
            fi
            exit;
        done
    fi
}

## code execution
createMagentoVersionTempFileIfNotExists

askToSelectTask