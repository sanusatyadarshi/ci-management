#!/bin/bash -e
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# This script clones the Hyperledger fabric repository,
# the fabric-ca repository, and runs the end-to-end tests
# with fabric-sdk-java.
set -o pipefail

# Clone fabric git repository
#############################
clone_fabric() {

  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
  REPO_NAME=fabric

  git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD

  cd $WD

  if [ "$FABRIC_COMMIT" == "latest" ]; then
    echo "Fabric commit is $FABRIC_COMMIT so go with this"
  else
    git checkout $FABRIC_COMMIT
    FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
  fi

  FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")

  # Build fabric Docker images
  set +x
  GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
  export GOROOT=/opt/go/go$GO_VER.linux.amd64
  export PATH=$GOROOT/bin:$PATH
  echo "----> GO_VER" $GO_VER
  set -x
  make docker docker-thirdparty
  docker images | grep hyperledger
}

if [ "$GERRIT_BRANCH" = "master" ]; then
   export NODE_ENV_VERSION=amd64-2.0.0-stable
   export NODE_ENV_TAG=2.0.0

   ########################
   # Pull nodenev image from nexus and re-tag to hyperledger/fabric-nodeenv
   #######################

   docker pull nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION
   docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv:amd64-$NODE_ENV_TAG
   docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv:amd64-latest
   docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv
   ##########
   docker images | grep hyperledger/fabric-nodeenv || true
fi

# Clone fabric-ca git repository
################################
clone_fabric_ca() {
  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
  CA_REPO_NAME=fabric-ca

  git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD

  cd $WD

  if [ "$FABRIC_CA_COMMIT" == "latest" ]; then
    echo "Fabric_CA commit is $FABRIC_COMMIT so go with this"
  else
    git checkout $FABRIC_CA_COMMIT
    CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
  fi

  CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")

  # Build CA Docker Images
  set +x
  GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
  export GOROOT=/opt/go/go$GO_VER.linux.amd64
  export PATH=$GOROOT/bin:$PATH
  echo "----> GO_VER" $GO_VER
  set -x
  make docker-fabric-ca
  docker images | grep hyperledger
}

# Run end-to-end Java SDK tests
################################
run_e2e_tests() {
  export WD=${WORKSPACE}
  cd $WD
  JAVA_SDK_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
  echo "=======>" "FABRIC COMMIT NUMBER" "-" $FABRIC_COMMIT_LEVEL "=======>" \
       "FABRIC CA COMMIT NUMBER" "-" $CA_COMMIT_LEVEL "=======>"             \
       "FABRIC SDK JAVA COMMIT NUMBER" "-" $JAVA_SDK_COMMIT_LEVEL            \
       >> commit_history.log
  export GOPATH=$WD/src/test/fixture
  cd $WD/src/test
  source cirun.sh
}

main() {
    # Skip build when the value is true
    if [[ "$FABRIC_NO_BUILD" = "" ]]; then
          clone_fabric
    fi
    # Skip build when the value is true
    if [[ "$FABRIC_CA_NO_BUILD" = "" ]]; then
          clone_fabric_ca
    fi
  run_e2e_tests
}

# shellcheck source=/dev/null
source "${WORKSPACE}/src/test/fabric_test_commitlevel.sh"

main
