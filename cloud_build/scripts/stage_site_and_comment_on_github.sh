#!/bin/bash
set -e

ls

echo "Deploying website to a staging channel on firebase..."
echo $_PR_NUMBER
echo $_HEAD_BRANCH
echo $PROJECT_ID
firebase hosting:channel:deploy --expires 7d pr$_PR_NUMBER-$_HEAD_BRANCH --project=$PROJECT_ID
FIREBASE_DEPLOY_RESPONSE=$(firebase hosting:channel:deploy --expires 7d pr$_PR_NUMBER-$_HEAD_BRANCH --project=$PROJECT_ID)
FIREBASE_STAGING_URL=$(echo $$FIREBASE_DEPLOY_RESPONSE | grep -Eo "https://$PROJECT_ID--[a-zA-Z0-9./?=_%:-]*")

echo "Logging into github under bot account..."
echo $$GH_PAT_TOKEN > token
gh auth login --with-token < token

echo "Commenting staging url on PR..."
PR_BODY=\
"Visit the preview URL for this PR (updated for commit $COMMIT_SHA):

$$FIREBASE_STAGING_URL"

gh pr comment $_PR_NUMBER --edit-last --body "$$PR_BODY" --repo $REPO_FULL_NAME || \
    gh pr comment $_PR_NUMBER --body "$$PR_BODY" --repo $REPO_FULL_NAME