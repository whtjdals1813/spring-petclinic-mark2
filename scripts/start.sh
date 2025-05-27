#!/bin/bash
cd /home/ubuntu/scripts
docker compose pull
docker compose up -d --build
