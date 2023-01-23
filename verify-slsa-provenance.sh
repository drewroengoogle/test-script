echo "Installing slsa-verifier..."
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@v2.0.1

echo "Verifying the provenance is valid and correct..."
slsa-verifier verify-image $(cat DOCKER_DIGEST_URL) \
  --source-uri https://github.com/drewroengoogle/test-script2 \
  --builder-id=https://cloudbuild.googleapis.com/GoogleHostedWorker@v0.3 \
  --provenance-path unverified-provenance.json
  
echo "Provenance has been successfully validated. We can proceed with the deployment!"

echo "Deploying....."
echo "Finished deployment"
