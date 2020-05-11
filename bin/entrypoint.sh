#!/bin/bash

set -e -xo pipefail

# import variables and functions
DIR=/usr/bin

# Don't alter the import order
. "$DIR"/global-variables.sh
. "$DIR"/util-methods.sh
. "$DIR"/git-api.sh

. "$DIR"/workflow.sh

# Parse Environment Variables
parse_env

export PR_NUMBER=$(jq -r ".number" "$GITHUB_EVENT_PATH")
export REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

export TARGET_BRANCH=$(jq -r ".pull_request.base.ref" "$GITHUB_EVENT_PATH")
export HEAD_SHA=$(jq -r ".pull_request.head.sha" "$GITHUB_EVENT_PATH")

echo "Collecting information about PR #$PR_NUMBER of $REPO_FULLNAME to $TARGET_BRANCH on $HEAD_SHA"

echo "## Workflow Conclusion"
echo "$WORKFLOW_CONCLUSION" # neutral, success, cancelled, timed_out, failure

echo "$GITHUB_EVENT_PATH"
cat "$GITHUB_EVENT_PATH"

echo "## checking perl version"
perl -v ||:

echo "## setup git repo"
git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$REPO_FULLNAME.git
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Play Action"
git fetch origin

echo "### Current HEAD"
git log -1

echo "### git log -1 origin/$TARGET_BRANCH"
git log -1 origin/$TARGET_BRANCH

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
echo "workflow triggered for action=$action"

# https://github.com/lots0logs/gh-action-auto-merge/blob/master/entrypoint.sh
if [ "$action" == "opened" ]; then
	check_openPullRequest
else
	echo "action '$action' is not supported"
	exit 0
fi

#/action/run.pl $action
