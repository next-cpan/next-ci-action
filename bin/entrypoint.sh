#!/bin/bash

set -xo pipefail

# import variables and functions
DIR=/usr/bin

# Don't alter the import order
. "$DIR"/global-variables.sh
. "$DIR"/util-methods.sh
. "$DIR"/git-api.sh

# Parse Environment Variables
parse_env

export PR_NUMBER=$(jq -r ".issue.number" "$GITHUB_EVENT_PATH")
export REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "Collecting information about PR #$PR_NUMBER of $REPO_FULLNAME..."

echo "## Workflow Conclusion"
echo "$WORKFLOW_CONCLUSION"

echo "$GITHUB_EVENT_PATH"
cat "$GITHUB_EVENT_PATH"

# setup git repo
set -o xtrace

git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$REPO_FULLNAME.git
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Play Action"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")

# https://github.com/lots0logs/gh-action-auto-merge/blob/master/entrypoint.sh

/action/run.pl $action
