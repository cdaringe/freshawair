#!/usr/bin/env bash
set -exo pipefail

# if [ -n "$NAS_IP" ]; then
#   echo no NAS_IP $NAS_IP
#   exit 1
# fi
dest_dir=/volume1/docker/freshawair
ui_src="$HOME/src/freshawair-ui"
curr_dir=$(dirname $PWD/a)

echo building ui app
cd "$ui_src"
yarn build
rm -rf public
mv $ui_src/build public
cd $curr_dir

function ssh_cmd () {
  ssh $NAS_IP -- "$@"
}

ssh_cmd mkdir -p $dest_dir

rsync -av \
  --exclude-from=".gitignore" \
  $PWD/ \
  $NAS_IP:$dest_dir/

ssh $NAS_IP /bin/bash << EOF
  cd $dest_dir
  bash deploy.start.sh
EOF
