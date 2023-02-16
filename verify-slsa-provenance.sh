#!/bin/bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Download the jq binary in order to obtain the artifact registry url from the
# docker image provenance.
echo "Installing jq using curl..."
apt update && apt install jq=1.5+dfsg-1.3 -y

# Download slsa-verifier in order to validate the docker image provenance.
echo "Installing slsa-verifier using go..."
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@a43888265e1f6aae98c924538298944f2721dcf0

# This command uses slsa-verifier to ensure the provenance has the correct
# source location and builder.
# "source-uri" is the original location of the source code
# "builder-id" is where the artifact was built (Note: GoogleHostedWorker is
# a GCP Cloud Build instance)
#
# Note: jq is used in order to obtain the full artifact registry url from
# the provenance metadata.
echo "Verifying the provenance is valid and correct..."
ls  
FULLY_QUALIFIED_DIGEST=$(cat unverified-provenance.json | \
  jq -r .image_summary.fully_qualified_digest)
slsa-verifier verify-image $FULLY_QUALIFIED_DIGEST \
  --source-uri https://github.com/drewroengoogle/test-script \
  --builder-id=https://cloudbuild.googleapis.com/GoogleHostedWorker@v0.3 \
  --provenance-path unverified-provenance.json

echo "Provenance has been successfully validated."
