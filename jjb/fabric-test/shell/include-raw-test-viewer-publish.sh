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
set -o pipefail

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
TAG=$GIT_COMMIT
STABLE_TAG=$PUSH_VERSION
export COMMIT_TAG=${TAG:0:7}

echo "----> Publishing TestViewer image to nexus3..."
echo

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test

docker build -t $ORG_NAME-testviewer tools/Testviewer

dockerTestViewerTag() {
  echo "==> $ORG_NAME-testviewer"
  echo
  docker tag $ORG_NAME-testviewer $NEXUS_URL/$ORG_NAME-testviewer:$STABLE_TAG
  docker tag $ORG_NAME-testviewer $NEXUS_URL/$ORG_NAME-testviewer:$STABLE_TAG-$COMMIT_TAG
  echo "==> $NEXUS_URL/$ORG_NAME-testviewer:$STABLE_TAG"
}

dockerTestViewerPush() {
  echo "==> $ORG_NAME-testviewer"
  echo
  docker push $NEXUS_URL/$ORG_NAME-testviewer:$STABLE_TAG
  docker push $NEXUS_URL/$ORG_NAME-testviewer:$STABLE_TAG-$COMMIT_TAG
  echo
  echo "==> $NEXUS_URL/$ORG_NAME-testviewer:$STABLE_TAG"
}

# Tag TestViewer Docker Images to Nexus Repository
echo "----> Tagging TestViewer image for nexus3 repo..."
echo
dockerTestViewerTag

# Push TestViewer Docker Images to Nexus Repository
echo "----> Pushing TestViewer image to nexus3 repo..."
echo
dockerTestViewerPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
