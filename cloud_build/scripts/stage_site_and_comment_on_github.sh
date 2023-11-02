#!/bin/bash
set -e

deploy_to_firebase_staging_channel () {
    echo "Deploying website to a staging channel on firebase..."

    FIREBASE_DEPLOY_RESPONSE=$(firebase hosting:channel:deploy --expires 7d pr$PR_NUMBER-$HEAD_BRANCH --project=$PROJECT_ID)
    echo "$FIREBASE_DEPLOY_RESPONSE"
    FIREBASE_STAGING_URL=$(grep -Eo "https://$PROJECT_ID--[a-zA-Z0-9./?=_%:-]*" <<< "$FIREBASE_DEPLOY_RESPONSE")
}

login_to_github() {
    echo "Logging into github under bot account..."

    echo $GH_PAT_TOKEN > token
    gh auth login --with-token < token
}

comment_staging_url_on_github () {
    echo "Commenting staging url on the PR..."
    echo -e "Visit the preview URL for this PR (updated for commit $COMMIT_SHA):\n\n$FIREBASE_STAGING_URL" > PR_BODY

    # The github CLI throws an error if --edit-last doesn't find a previous
    # comment, so this edits the last comment, but if it doesn't exist,
    # leave a new comment.
    gh pr comment $PR_NUMBER --edit-last --body-file PR_BODY --repo $REPO_FULL_NAME || \
        gh pr comment $PR_NUMBER ---body-file PR_BODY --repo $REPO_FULL_NAME
}

deploy_to_firebase_staging_channel
login_to_github
comment_staging_url_on_github