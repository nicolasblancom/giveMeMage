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
## $1 sets to create project name temp variables too
function createVariablesTempFilesIfNotExist() {
    local createProject=$1
    
    if [ ! -d $temp_vars_dir ]; then
        mkdir $temp_vars_dir
    fi
    
    createMagentoVersionTempFileIfNotExists
    createPhpVersionTempFileIfNotExists
    
    # if is set or not empty
    if [ ! -z $createProject ]; then
        createProjectNameTempFileIfNotExists
    fi
}

function createMagentoVersionTempFileIfNotExists() {
    if [ ! -f $magento_version_temp_file_path ]; then
        local PS3="Elige versión de magento:";

        local versiones="2.4.1 2.4.2";

        select version in $versiones
        do          
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
        local PS3="Elige script a ejecutar (cualquier otra opción para terminar):"

        local tasks=" Preparar local para la v. de magento elegida | Crear nuevo proyecto local "

        select task in $tasks
        do
            if [ $REPLY = 1 ]; then
                prepareDevilboxForMageVersion
            elif [ $REPLY = 2 ]; then
                createDevilboxProject
            else
                logWarn 'Fin'
                exit
            fi
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

function createDevilboxProject() {
    createVariablesTempFilesIfNotExist "createProject"

    # create project dir in devilbox project dir
    local currentDir=$PWD
    local devilboxInstallationDirPath=$(getDevilboxConfigValue "devilboxInstallationDir")
    local projectName=$(readFirstLineOfFile $project_name_temp_file_path)
    local devilboxProjectsDirPath=$(getDevilboxConfigValue "devilboxProjectsDir")
    
    cd $devilboxInstallationDirPath
    if [ ! -d $devilboxProjectsDirPath ]; then
        logError "No existe el directorio $devilboxProjectsDirPath"
        exit 1
    fi
   
    cd $devilboxProjectsDirPath
    if [ -d $projectName ]; then
        logWarn "Ya existe el directorio $projectName"
        return 0
    fi

    mkdir -p "$projectName/htdocs"
    log "Creado el directorio de proyecto: $projectName"

    cd $currentDir
}

## code execution
createVariablesTempFilesIfNotExist

askToSelectTask