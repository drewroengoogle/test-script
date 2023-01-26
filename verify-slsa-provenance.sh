#!/bin/bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

gcloud artifacts docker images describe \
  us-docker.pkg.dev/drewroen-sandbox/appengine/default.version-12345:latest \
  --show-provenance --format json \
  > unverified-provenance.json
gcloud artifacts docker images describe \
  us-docker.pkg.dev/drewroen-sandbox/appengine/default.version-12345:latest \
   | grep fully_qualified_digest \
   | cut -c 27- \
   > DOCKER_DIGEST_URL

echo "Installing slsa-verifier..."
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@v2.0.1

echo "Verifying the provenance is valid and correct..."
slsa-verifier verify-image $(cat DOCKER_DIGEST_URL) \
  --source-uri https://github.com/drewroengoogle/test-script \
  --builder-id=https://cloudbuild.googleapis.com/GoogleHostedWorker@v0.3 \
  --provenance-path unverified-provenance.json
  
echo "Provenance has been successfully validated. We can proceed with the deployment!"

echo "Deploying....."
echo "Finished deployment"
