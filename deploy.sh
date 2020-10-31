#!/usr/bin/env bash
set -exo pipefail

files_to_sync=("db.init" "docker-compose.yml" "deploy.start.sh")


# if [ -n "$NAS_IP" ]; then
#   echo no NAS_IP $NAS_IP
#   exit 1
# fi
dest_dir=/volume1/docker/freshawair

function ssh_cmd () {
  ssh $NAS_IP -- "$@"
}

ssh_cmd mkdir -p $dest_dir

for f in "${files_to_sync[@]}"; do
  scp -r $f $NAS_IP:$dest_dir/$f
done

ssh $NAS_IP /bin/bash << EOF
  cd $dest_dir
  bash deploy.start.sh
EOF
