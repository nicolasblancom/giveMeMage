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

function listIncludesItem() {
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

function readFirstLineOfFile() {
    local file="$1"

    echo $(head -n 1 $file)
}

function stringContainsSubString() {
    local string=$1
    local substring=$2

    if [[ "$string" == *"$substring"* ]]; then
        # found
        return 0
    else
        # not found
        return 1
    fi
}

###################################

## variables to source
temp_vars_dir="temp_vars";
magento_version_temp_file_path="$temp_vars_dir/magento_version_temp_file";
project_name_temp_file_path="$temp_vars_dir/project_name_temp_file";
php_version_temp_file_path="$temp_vars_dir/php_version_temp_file";
vars_dir="vars";
mage_vars_dir="$vars_dir/mage"

## functions declarations
function createVariablesTempFilesIfNotExist() {
    createMagentoVersionTempFileIfNotExists
    createProjectNameTempFileIfNotExists
    createPhpVersionTempFileIfNotExists
}

function createMagentoVersionTempFileIfNotExists() {
    if [ ! -f $magento_version_temp_file_path ]; then
        local PS3="Elige versión de magento:";

        local versiones="2.4.1 2.4.2";

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
    else
        local existentVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
        logWarn "Magento version already selected: [$existentVersion]"
    fi
}

function createProjectNameTempFileIfNotExists() {
    if [ ! -f $project_name_temp_file_path ]; then
        read -p "Introduce nombre del proyecto (sin espacios ni extension de dominio):" projectName

        touch $project_name_temp_file_path
        echo $projectName > "$project_name_temp_file_path";
    else
        local existentProjectName=$(readFirstLineOfFile $project_name_temp_file_path)
        logWarn "Project name already introduced: [$existentProjectName]"
    fi
}

function createPhpVersionTempFileIfNotExists() {
    local phpVersion=$(getPhpVersionForMageVersion)

    if [ ! -f $php_version_temp_file_path ]; then
        touch $php_version_temp_file_path
        echo $phpVersion > "$php_version_temp_file_path";
    else
        local existentPhpVersion=$(readFirstLineOfFile $php_version_temp_file_path)
        logWarn "PHP version already set: [$existentPhpVersion]"
    fi
}

function getPhpVersionForMageVersion() {
    local magentoVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
    local envForThisMageVersionFilePath="$mage_vars_dir/$magentoVersion/env_for_devilbox"
    local found=0

    while IFS= read -r line
    do
        if `stringContainsSubString "$line" "PHP_SERVER="` ; then
            echo local retval=$line | awk -F'=' {'print $NF'}
            found=1
        fi
    done < "$envForThisMageVersionFilePath"

    if [ $found -eq 0 ]; then
        logError "Not PHP version found in $envForThisMageVersionFilePath file";
        exit 1
    fi
}

function getDevilboxConfigValue() {
    local devilboxInstallationDirLine=$1

    while IFS= read -r line
    do
        if `stringContainsSubString "$line" "$devilboxInstallationDirLine"` ; then
            echo local retval=$line | awk -F'=' {'print $NF'}
        fi
    done < "$vars_dir/devilbox"
}

function askToSelectTask() {
    if [ -f $magento_version_temp_file_path ]; then
        local IFS='|'
        local PS3="Elige script a ejecutar:"

        local tasks=" Preparar local para una v. de magento | Crear nuevo proyecto local "

        select task in $tasks
        do
            if [ $REPLY = 1 ]; then
                prepareDevilboxForMageVersion
                echo
            else
                log otra
                echo
            fi
            exit;
        done
    fi
}

function prepareDevilboxForMageVersion() {
    local currentDir=$PWD
    local devilboxInstallationDirPath=$(getDevilboxConfigValue "devilboxInstallationDir")
    local devilboxProjectsDirPath=$(getDevilboxConfigValue "devilboxProjectsDir")
    local magentoVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
    local envForThisMageVersionFilePath="$mage_vars_dir/$magentoVersion/env_for_devilbox"

    # deleteDevilboxVarsFromEnvFile

    # move to devilbox installation dir and create a .env file from scratch
    cd "$devilboxInstallationDirPath"
    rm ".env" > /dev/null 2>&1
    cp "env-example" ".env" > /dev/null 2>&1
    cd $currentDir

    # insert devilbox config variables needed for this magento version
    cat $envForThisMageVersionFilePath >> "$devilboxInstallationDirPath/.env"
    
    # Insert a line before match found
    local sedSearchPattern='/^##END-GIVEMEMAGE.*/i'
    local sedDevilboxProjectsDirPath="HOST_PATH_HTTPD_DATADIR=$devilboxProjectsDirPath"
    local sedDevilboxEnvFilePath="$devilboxInstallationDirPath/.env"
    sed -i "$sedSearchPattern $sedDevilboxProjectsDirPath" "$sedDevilboxEnvFilePath"
}

## code execution
createVariablesTempFilesIfNotExist

askToSelectTask