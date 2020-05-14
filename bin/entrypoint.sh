#!/bin/bash

set -e -xo pipefail

# import variables and functions
DIR=/usr/bin

# Don't alter the import order
. "$DIR"/global-variables.sh
. "$DIR"/util-methods.sh
. "$DIR"/git-api.sh

#. "$DIR"/workflow.sh

# Parse Environment Variables
parse_env

export PR_NUMBER=$(jq -r ".number" "$GITHUB_EVENT_PATH")
#export REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "## Collecting information about Pull Request #${PR_NUMBER}"

export PR_STATE_PATH=/tmp/pr_state.${PR_NUMBER}.json
curl -X GET -s -H "${AUTH_HEADER}" -H "${API_HEADER}" \
          "${URI}/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" \
          -o $PR_STATE_PATH

echo "## Setting some variables"
export TARGET_BRANCH=$(jq -r ".base.ref" "$PR_STATE_PATH")
export HEAD_SHA=$(jq -r ".head.sha" "$PR_STATE_PATH")
export HEAD_REPO=$(jq -r .head.repo.full_name "$PR_STATE_PATH")
export HEAD_BRANCH=$(jq -r .head.ref "$PR_STATE_PATH")

echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "TARGET_BRANCH:     $TARGET_BRANCH"
echo "HEAD_SHA:          $HEAD_SHA"
echo "HEAD_REPO:         $HEAD_REPO"
echo "HEAD_BRANCH:       $HEAD_BRANCH"

echo "## Workflow Conclusion"
echo "$WORKFLOW_CONCLUSION" # neutral, success, cancelled, timed_out, failure

echo "PR_STATE_PATH: $PR_STATE_PATH"
echo "============================================="
cat $PR_STATE_PATH
echo "============================================="

echo "GITHUB_EVENT_PATH: $GITHUB_EVENT_PATH"
echo "============================================="
cat "$GITHUB_EVENT_PATH"
echo "============================================="

echo "# Perl Version: " $(perl -E 'say $]')

echo "## setup git repo"
export GIT_WORK_TREE=$PWD
echo "GIT_WORK_TREE: $GIT_WORK_TREE"

git config --global user.email "actions@github.com"
git config --global user.name  "GitHub Play Action"

git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git
git remote add       fork https://x-access-token:$COMMITTER_TOKEN@github.com/$HEAD_REPO.git

git fetch origin $TARGET_BRANCH
git fetch fork   $HEAD_BRANCH

# make sure we are on the branch
git checkout -b $HEAD_BRANCH fork/$HEAD_BRANCH

# https://github.com/cirrus-actions/rebase/blob/master/entrypoint.sh

echo "### Current HEAD"
git log -1

echo "### git log -1 origin/$TARGET_BRANCH"
git log -1 origin/$TARGET_BRANCH

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
echo "workflow triggered for action=$action"

# https://github.com/lots0logs/gh-action-auto-merge/blob/master/entrypoint.sh
# if [ "$action" == "opened" ]; then
# 	check_openPullRequest
# else
# 	echo "action '$action' is not supported"
# 	exit 0
# fi

/action/run.pl $action
