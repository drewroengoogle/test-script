#!/bin/bash

# Fail on any error.
set -e
# Display commands to stderr.
set -x

readonly ROOT_DIR="${PWD}"

# Print some runtime details that might be useful for debugging.
env

readonly SDK_FILENAME="dartsdk-macos-$ARCH-release.zip"
readonly DART_LANG_DIR="${KOKORO_PIPER_DIR}/google3/third_party/dart_lang"
readonly RELEASE_DIR="${DART_LANG_DIR}/g3tools/release"
readonly SDK="${RELEASE_DIR}/${SDK_FILENAME}"
readonly ENTITLEMENTS="${RELEASE_DIR}/Entitlements.plist"

readonly ARTIFACTS_DIR="${ROOT_DIR}/artifacts"

readonly SDK_DIR="${ARTIFACTS_DIR}/dart-sdk"

declare -ar CODESIGN_ARGS=(-f -s "Developer ID Application: Google LLC (EQHXZ8M8AV)" \
   --timestamp --options=runtime)

function sign_with_entitlements() {
  [[ -f ${1} && -f ${2} ]] || exit 1
  "${codesign_cmd}" "${CODESIGN_ARGS[@]}" --entitlements="${2}" "${1}"
}

function sign() {
  [[ -f ${1} ]] || exit 1
  "${codesign_cmd}" "${CODESIGN_ARGS[@]}" "${1}"
}

function sign_all() {
  sign_with_entitlements "${SDK_DIR}/bin/dart" \
    "${RELEASE_DIR}/Entitlements_dart.plist"
  sign_with_entitlements "${SDK_DIR}/bin/dartaotruntime" \
    "${RELEASE_DIR}/Entitlements_dartaotruntime.plist"
  sign_with_entitlements "${SDK_DIR}/bin/utils/gen_snapshot" \
    "${RELEASE_DIR}/Entitlements_gen_snapshot.plist"
}

declare codesign_cmd=codesign # changed to echo in presubmit.sh
mkdir "${ARTIFACTS_DIR}"
unzip -q "${SDK}" -d "${ARTIFACTS_DIR}"

# Find the version and channel being signed.
read -r VERSION < "${SDK_DIR}/version"
readonly VERSION
case "${VERSION}" in
*-*.0.dev)
  readonly CHANNEL="dev"
  ;;
*-*.*.beta)
  readonly CHANNEL="beta"
  ;;
*)
  readonly CHANNEL="stable"
  ;;
esac

readonly SDK_GCS_URL="gs://dart-archive/channels/${CHANNEL}/raw/${VERSION}/sdk"

# BCID Enforcement Point per go/bcid-for-dart. Submit the artifact to piper for
# signing ONLY if it matches the signed attestation and passes the policy as
# checked by the BCID Verification API.
gsutil cp "${SDK_GCS_URL}/${SDK_FILENAME}.intoto.jsonl" "${SDK}.intoto.jsonl"
# Authenticate using exported service account credentials, which must be
# refreshed per go/dart-release-eng#bcid-verifier every 90 days.
# bcid-verifier@dart-ci.iam.gserviceaccount.com ONLY has access to invoke the
# harmless BCID Verification API.
declare -xr GOOGLE_APPLICATION_CREDENTIALS="${KOKORO_KEYSTORE_DIR}/76971_bcid-verifier"
gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
# Avoid leaking credentials to the log via set -x
printf "Authorization: Bearer " > authorization
gcloud auth print-access-token \
  --scopes=https://www.googleapis.com/auth/bcid_verify,https://www.googleapis.com/auth/cloud-platform \
  >> authorization
cat > request.json << EOF
{
  "content_hash": {
    "values": {
      "hash": "$(shasum -a 256 "$SDK"| grep -Eo '^[^ ]*')",
      "type": "SHA256"
    }
  },
  "attestations": [
    "$(sed -E 's/"/\\"/g' "$SDK.intoto.jsonl")"
  ]
}
EOF
curl \
  -H @authorization \
  -H 'Content-Type: application/json' \
  -d @request.json \
  https://bcidsoftwareverifier-pa.googleapis.com/v1/verifySoftwareArtifact/misc_software%3A%2F%2Fdart%2Fsdk%2Fmacos \
  -o response.json
cat response.json
readonly ALLOWED=$(jq -r .allowed < response.json)
if [ "${ALLOWED}" != true ]; then
  echo "BCID Verification Failure: ${SDK} failed verification"
  jq -r .rejectionMessage < response.json
  exit 1
fi
echo "BCID Verification Success, Congratulations!"