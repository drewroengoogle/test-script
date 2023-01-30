#!/bin/bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

echo "Installing slsa-verifier..."
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@v2.0.1

# This command uses slsa-verifier to ensure the provenance has the correct
# source location and builder.
# "source-uri" is the location of the source code
# "builder-id" is where the artifact was built (Note: GoogleHostedWorker is
# a GCP Cloud Build instance)
echo "Verifying the provenance is valid and correct..."
slsa-verifier verify-image $3 \
  --source-uri https://github.com/drewroengoogle/test-script \
  --builder-id=https://cloudbuild.googleapis.com/GoogleHostedWorker@v0.3 \
  --provenance-path unverified-provenance.json

echo "Provenance has been successfully validated."
