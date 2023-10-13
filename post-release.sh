#!/bin/bash

#
# Licensed to Laurent Broudoux (the "Author") under one or more contributor license agreements.
# See the NOTICE file distributed with this work for additional information regarding copyright
# ownership. Author licenses this file to you under the Apache License, Version 2.0 (the  "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

root_dir=$(pwd)

# Need 2 arguments: first is version we just release, second is issue id for release.
if (( $# < 2 ));; then
  # Package Helm chart.
  cd install/kubernetes
  helm package microcks
  echo $root_dir

  # Get a local copy of microcks.io and move help package.
  mkdir $root_dir/tmp && cd $root_dir/tmp
  git clone https://github.com/microcks/microcks.io && cd microcks.io
  mkdir ./static/helm/tmp
  mv $root_dir/install/kubernetes/microcks-$1.tgz ./static/helm/tmp/microcks-$1.tgz

  # Update the index.yaml file of Help repo.
  mv ./static/helm/index.yaml ./static/helm/index.yaml.backup
  helm repo index static/helm/tmp --url https://microcks.io/helm --merge ./static/helm/index.yaml.backup
  mv ./static/helm/tmp/index.yaml ./static/helm/index.yaml
  mv ./static/helm/tmp/microcks-$1.tgz ./static/helm/microcks-$1.tgz

  # Add and commit before cleaning up things.
  git add ./static/helm/microcks-$1.tgz
  git commit -m 'microcks/microcks#$2 chore: Release Helm chart for $1' ./static/helm/index.yaml ./static/helm/microcks-$1.tgz
  git push origin main

  rm -rf ./static/helm/tmp
  rm ./static/helm/index.yaml.backup

  # Get back to root.
  cd $root_dir
  rm -rf $root_dir/tmp

  # Update container image version in docker-compose, podman-compose and helm chart files.
  if [ "$(uname)" == "Darwin" ]; then
    sed -i '' 's=quay.io/microcks/microcks:'"$1"'=quay.io/microcks/microcks:nightly=g' install/docker-compose/docker-compose*.yml
    sed -i '' 's=quay.io/microcks/microcks-async-minion:'"$1"'=quay.io/microcks/microcks-async-minion:nightly=g' install/docker-compose/docker-compose*.yml
    sed -i '' 's=quay.io/microcks/microcks:'"$1"'=quay.io/microcks/microcks:nightly=g' install/kubernetes/microcks/values.yaml
    sed -i '' 's=quay.io/microcks/microcks-async-minion:'"$1"'=quay.io/microcks/microcks-async-minion:nightly=g' install/kubernetes/microcks/values.yaml
    sed -i '' 's=quay.io/microcks/microcks:'"$1"'=quay.io/microcks/microcks:'"$1"'=g' install/podman-compose/microcks-*.yml
    sed -i '' 's=quay.io/microcks/microcks-async-minion:'"$1"'=quay.io/microcks/microcks-async-minion:nightly=g' install/podman-compose/microcks-*.yml
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    sed -i 's=quay.io/microcks/microcks:'"$1"'=quay.io/microcks/microcks:nightly=g' install/docker-compose/docker-compose.yml
    sed -i 's=quay.io/microcks/microcks-async-minion:'"$1"'=quay.io/microcks/microcks-async-minion:nightly=g' install/docker-compose/docker-compose*.yml
    sed -i 's=quay.io/microcks/microcks:'"$1"'=quay.io/microcks/microcks:nightly=g' install/kubernetes/microcks/values.yaml
    sed -i 's=quay.io/microcks/microcks-async-minion:'"$1"'=quay.io/microcks/microcks-async-minion:nightly=g' install/kubernetes/microcks/values.yaml
    sed -i 's=quay.io/microcks/microcks:'"$1"'=quay.io/microcks/microcks:nightly=g' install/podman-compose/microcks-*.yml
    sed -i 's=quay.io/microcks/microcks-async-minion:'"$1"'=quay.io/microcks/microcks-async-minion:nightly=g' install/podman-compose/microcks-*.yml
  fi
else
  echo "post-release.sh must be called with <version> <release-issue> as 1st argument. Example:"
  echo "$ ./post-release.sh 1.7.1 837"
fi
