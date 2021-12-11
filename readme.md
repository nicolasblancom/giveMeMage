In this `vars` directory, we have several files that the script uses to work. This files must be edited to work as we want.

- mage/{magento-version}/env_for_devilbox: the variables that will be copied at the end of the devilbox `.env` file for that particular magento version
- devilbox: the variables that configuratse devilbox in our machine (`devilboxProjectsDir` will be copied to `.env` file)


---

- selector de tareas/scripts
- switch entorno local devilbox para una v de magento 2 concreta: 
    --> .env_give_me_magento con variables a usar y mapeo versiones (p ej docker-compose.overide y v magento), todo partiendo desde una v de magento como un array
    --> docker-compse, install script, start script van con v magento; php.ini va con v php --> doble mapeo

    copiar .env-example, setear variables .env desde .env_give_me_magento y desde .env_scr_m2_v*, 
    copiar .docker-compose.override de la version de magento que toca
    copia custom.ini a php.ini
    copia start script
    crear ficheros temporales con variables interscript
- crear proyecto devilbox magento 2
    crear directorio
    mostrar en consola entrada en hosts o intenta meterla
    mostrar comandos a ejecutar dentro del shell devilbox