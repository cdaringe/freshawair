#!/usr/bin/env bash
/usr/local/bin/docker-compose down
/usr/local/bin/docker-compose build --parallel
/usr/local/bin/docker-compose up -d
