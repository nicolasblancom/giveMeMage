#!/usr/bin/env bash
cd ~/devilbox && \
docker-compose stop && \
docker-compose rm -f && \
docker-compose up -d httpd php mysql mailhog elastic
