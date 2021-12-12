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
        logError "File $filePath does not exist in getVarFromFile method"
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
        local PS3="Choose a Magento version: ";

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
        read -p "Enter project name (no spaces or domain extension): " projectName

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
        local PS3="Choose a task (any other option, finish the script): "

        local tasks=" Prepare local devilbox for the chosen Magento version | Create new local project dir | Create Magento installation script in a project dir "

        select task in $tasks
        do
            if [ $REPLY = 1 ]; then
                prepareDevilboxForMageVersion
            elif [ $REPLY = 2 ]; then
                createDevilboxProject
            elif [ $REPLY = 3 ]; then
                createMagentoInstallationScriptAndMoveToProject
            else
                logInfo 'END'
                exit
            fi
        done
    fi
}

function prepareDevilboxForMageVersion() {
    appendDevilboxEnvFileForThisMageVersion
    copyDockerComposeOverrideForThisMageVersion
    copyCustomIniForThisMageVersion
    copyDevilboxStartScriptForThisMageVersion
    # copyMagentoInstallScriptForThisMageVersion
}

function appendDevilboxEnvFileForThisMageVersion() {
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

function copyDockerComposeOverrideForThisMageVersion() {
    if [ ! -f $magento_version_temp_file_path ]; then
        logError "No magento version yet selected"
        return 1
    fi

    local currentDir=$PWD
    local devilboxInstallationDirPath=$(getDevilboxConfigValue "devilboxInstallationDir")
    local magentoVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
    local dockerComposeOverrideFileName="docker-compose.override.yml"
    local dockerComposeOverrideFilePath=$mage_vars_dir/$magentoVersion/$dockerComposeOverrideFileName

    cd $devilboxInstallationDirPath
    if [ -f $dockerComposeOverrideFileName ]; then
        rm $dockerComposeOverrideFileName
    fi
    cd $currentDir

    cp $dockerComposeOverrideFilePath "$devilboxInstallationDirPath/$dockerComposeOverrideFileName"
}

function copyCustomIniForThisMageVersion() {
    local currentDir=$PWD
    local devilboxInstallationDirPath=$(getDevilboxConfigValue "devilboxInstallationDir")
    local magentoVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
    local phpVersion=$(readFirstLineOfFile $php_version_temp_file_path)
    local customIniFileName="custom.ini"
    local customIniFilePath="$mage_vars_dir/$magentoVersion/$customIniFileName"

    cd $devilboxInstallationDirPath
    cd "cfg/php-ini-$phpVersion"
    if [ -f $customIniFileName ]; then
        rm $customIniFileName
    fi
    cd $currentDir

    cp $customIniFilePath "$devilboxInstallationDirPath/cfg/php-ini-$phpVersion"
}

function copyDevilboxStartScriptForThisMageVersion() {
    local currentDir=$PWD
    local devilboxInstallationDirPath=$(getDevilboxConfigValue "devilboxInstallationDir")
    local magentoVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
    local devilBoxStartScriptName="_start.sh"
    local devilBoxStartScriptFilePath=$mage_vars_dir/$magentoVersion/$devilBoxStartScriptName

    cd $devilboxInstallationDirPath
    if [ -f $devilBoxStartScriptName ]; then
        rm $devilBoxStartScriptName
    fi
    cd $currentDir

    cp $devilBoxStartScriptFilePath $devilboxInstallationDirPath
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
        logError "Directory does not exist: $devilboxProjectsDirPath"
        exit 1
    fi
   
    cd $devilboxProjectsDirPath
    if [ -d $projectName ]; then
        logWarn "Directory already exists: $projectName"
        return 0
    fi

    mkdir -p "$projectName/htdocs"
    log "Project dir created: $projectName"

    cd $currentDir

    addNewHostsEntry $projectName
}

function addNewHostsEntry() {
    local projectName=$1

    # if is set or not empty
    if [ -z $projectName ]; then
        logError "Not project name provided to addNewHostsEntry method"
        exit 1
    fi

    local etcHostsFilePath=$(getDevilboxConfigValue "etcHosts")
    local newHostsLine="127.0.0.1 $projectName.loc"
    local found=0

    # parse line by line /etc/hosts and search for a line with the project name
    while IFS= read -r line
    do
        if `stringContainsSubString "$line" "$projectName"` ; then
            found=1
        fi
    done < "$etcHostsFilePath"

    if [ $found -eq 0 ]; then
        logWarn "Do not forget to insert in $etcHostsFilePath: '$newHostsLine'";
    else
        logWarn "'$newHostsLine' already exists in $etcHostsFilePath";
    fi
}

function createMagentoInstallationScriptAndMoveToProject() {
    local currentDir=$PWD
    local devilboxInstallationDirPath=$(getDevilboxConfigValue "devilboxInstallationDir")
    local devilboxProjectsDirPath=$(getDevilboxConfigValue "devilboxProjectsDir")
    local magentoVersion=$(readFirstLineOfFile $magento_version_temp_file_path)
    local installMagentoScritpFileName="install_magento.sh"
    local installMagentoScritpFilePath="$mage_vars_dir/$magentoVersion/$installMagentoScritpFileName"
    local authJsonFileName="auth.json"
    local authJsonFilePath="$mage_vars_dir/$magentoVersion/$authJsonFileName"
    local installationScriptNewDirName="givememageInstallMagento"
    local installationDetailsFeedbackFileName="admin_credentials.txt"
    
    cd $devilboxInstallationDirPath; cd $devilboxProjectsDirPath
    
    # select giving as options the list of project dirs
    local IFS=$'\n'
    local PS3="Choose a project directory to create the installation script (a new givememageInstallMagento directory will be created): "
    local devilboxProjectsList=$(ls -d */)

    select projectDir in $devilboxProjectsList
    do
        cd $projectDir
        local projectNameFromDirName=$(echo "$projectDir" | sed 's,/,,g') # remove slash from dir name
        
        if [ ! -d $installationScriptNewDirName ]; then 
            mkdir $installationScriptNewDirName
        
            cp "$currentDir/$installMagentoScritpFilePath" $installationScriptNewDirName
            cp "$currentDir/$authJsonFilePath" $installationScriptNewDirName

            cd $installationScriptNewDirName
            
            # replace in script database creation with project_name
            sed -i "s/##project_name##/$projectNameFromDirName/" $installMagentoScritpFileName

            # replace in script download magento url with magento_version
            sed -i "s/##magento_version##/$magentoVersion/" $installMagentoScritpFileName

            logInfo 'Copied an auth.json file. Please edit it and insert your own credentials (those are functional although).'
            logInfo 'Execute in a shel this command: '
            log "cd $devilboxInstallationDirPath && ./_start.sh && ./shell.sh"
            logInfo 'Once your are inside devilbox container, run magento installation: '
            log "cd $projectNameFromDirName/$installationScriptNewDirName && ./$installMagentoScritpFileName"
            
            touch $installationDetailsFeedbackFileName
            echo "Front url: http://$projectNameFromDirName.loc \n" >> $installationDetailsFeedbackFileName
            echo "Admin url: http://$projectNameFromDirName.loc/admin123 \n" >> $installationDetailsFeedbackFileName
            echo "Admin user: admin \n" >> $installationDetailsFeedbackFileName
            echo "Admin password: g9egcwUE6WEGsyw98kKB4hu \n" >> $installationDetailsFeedbackFileName
            logInfo "Admin credentials and url are stored in a file: $installMagentoScritpFileName/$installationDetailsFeedbackFileName"
        else
            logError "There is already a givememageInstallMagento dir!! Delete it first if you want to create installation script"
        fi

        cd $currentDir
        break
    done

    cd $currentDir
}

## code execution
createVariablesTempFilesIfNotExist

askToSelectTask