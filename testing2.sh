gcloud config set account bcid-validator@drewroen-sandbox.iam.gserviceaccount.com

gsutil cp gs://drewroen-test-bucket-bcid/flutter_patched_sdk.zip .
gsutil cp gs://drewroen-test-bucket-bcid/flutter_patched_sdk.zip.attestation .
gsutil cp gs://drewroen-test-bucket-bcid/flutter_patched_sdk.zip.intoto.jsonl .

ls