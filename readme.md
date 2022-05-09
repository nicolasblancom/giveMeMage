# GiveMeMage

A script that installs Magento 2 in a Devilbox local development environment.

It configurates Devilbox for a given Magento version, also creates the needed directories and gives you needed instructions to follow.

## Prerequisites

Devilbox installed. See [installation steps in the docs](https://devilbox.readthedocs.io/en/latest/getting-started/install-the-devilbox.html)

## Usage

First of all, set in `giveMeMage/devilbox` the three needed variables **using full paths**. For example:

```
devilboxInstallationDir=/home/someone/devilbox
devilboxProjectsDir=../www-projects
etcHosts=/etc/hosts
```

NOTE: `devilboxProjectsDir` is the variable set in your Devilbox `.env` file as `HOST_PATH_HTTPD_DATADIR`

Change directory to the giveMeMage installation directoy 

```cd giveMeMage``` 

and execute 

```./main.hs``` 

(if not execution pemissions given yet to this file, do first `sudo chmod +x main.sh`)

You will be asked to choose a magento version. After that you will be asked for what task you want to do.

**When you need to start over again** choose the task to start again (delete temporary files).

### Possible tasks

**1) Prepare local devilbox for the chosen Magento version** will create devilbox needed files for the Magento version you selected (files: `.env`, `docker-compose.override.yml`, `custom.ini`, `_start.sh`). The `_start.sh` script will start needed devilbox containers

**2) Create new local project dir** will just create a new directory named as you want for a new devilbox project. Inside it will create a default `htdocs` directory

**3) Create Magento installation script in a project dir** will copy an `auth.json` and an already prepared script `install_magento.sh` into your devilbox project, in a new `givememageInstallMagento` directory. You will be shown a list of your devilbox project to choose which one you want. You will be given to run two commands, just copy and paste them in a new shell.
The installation script will do these things for you:
- create sthe database (with the same name as the project directory)
- copies `auth.json` so you don't have to enter any passwords
- downloads magento with `composer create-project` command
- runs a magento installation. Admin credentials will be:
    - admin user: admin
    - admin password: g9egcwUE6WEGsyw98kKB4hu
- sets correct file permissions
- disables modules: Magento_TwoFactorAuth
- installs modules: mageplaza/magento-2-spanish-language-pack
- makes all the necesary steps to enable grunt for local development (you will have to configure manually `dev/tools/grunt/configs/local-themes.js`)
- sets deploy mode to developer, executes a "setup upgrade", "compile" and "deploy" Magento commands

## Basic dev notes to know about

When executing the script, it stores some variables in temporary files located under `temp_vars` directory.

In this `vars` directory, we have several files that the script uses to work. This files must be edited to work as we want.

- **mage/{magento-version}/_start.sh**: a script that will be copied to your Devilbox installation directory to just be run and start all needed docker containers
- **mage/{magento-version}/auth.json**: credentials for composer. Maybe you want to set your own ones inside this file
- **mage/{magento-version}/custom.ini**: sets php.ini for Devilbox
- **mage/{magento-version}/docker-compose.override.yml**: file to copy to devilbox installation dir. It enables needed additional devilbox containers
- **mage/{magento-version}/env_for_devilbox**: the variables that will be copied at the end of the devilbox `.env` file for that particular magento version
- **mage/{magento-version}/install_magento.sh**: a script that will be copied to your Devilbox projets directory to just be run and install Magento
- **devilbox**: the variables that configuratse devilbox in our machine (`devilboxProjectsDir` will be copied to `.env` file)

## How do I add a new version of Magento to be installed with this script

- Add new version in `createMagentoVersionTempFileIfNotExists` function in `main.sh`
- Copy `vars/mage/{someVersion}` into exactly the version added in `createMagentoVersionTempFileIfNotExists`.
- Modify new copied `vars/mage/{someVersion}` files
    - _start.sh (probably no change needed)
    - auth.json (probably no change needed)
    - custom.ini (probably no change needed)
    - docker-compose.override.yml
    - env_for_devilbox
    - install_magento.sh --> probably need change only in: 
        - `install_magento` for admin credentials, elastic credentiales, database credentials)
        - `post_install_steps` for further steps like installing some composer dependency or disabling some module
        - `finish_installation` for final operations like nomal magento commands