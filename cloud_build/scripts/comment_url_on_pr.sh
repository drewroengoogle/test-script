#!/bin/bash
set -e

download_github_cli () {
    apt update && apt install -y \
    curl \
    gpg
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg;
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null;
    apt update && apt install -y gh;
}

log_into_github_account() {
    echo $GH_PAT_TOKEN > token
    gh auth login --with-token < token
}

comment_url_on_pr() {
    PR_BODY=\
    "Visit the preview URL for this PR (updated for commit $COMMIT_SHA):

    $(cat ../../FIREBASE_STAGING_URL)"

    gh pr comment $_PR_NUMBER --edit-last --body "$$PR_BODY" --repo $REPO_FULL_NAME || \
    gh pr comment $_PR_NUMBER --body "$$PR_BODY" --repo $REPO_FULL_NAME
}

echo "Installing github cli (using instructions from https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt)..."
# download_github_cli

echo "Logging into github under bot account..."
# log_into_github_account

echo "Commenting staging url on PR..."
comment_url_on_pr