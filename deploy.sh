#!/usr/bin/env bash
set -exo pipefail

# if [ -n "$NAS_IP" ]; then
#   echo no NAS_IP $NAS_IP
#   exit 1
# fi
dest_dir=/volume1/docker/freshawair

function ssh_cmd () {
  ssh $NAS_IP -- "$@"
}

ssh_cmd mkdir -p $dest_dir
scp -r ./db.init $NAS_IP:$dest_dir/db.init
scp -r ./docker-compose.yml $NAS_IP:$dest_dir/docker-compose.yml
ssh_cmd sudo docker-compose down || true
ssh_cmd sudo docker-compose up -d &
