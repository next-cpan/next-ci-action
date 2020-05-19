#!/bin/bash

set -e +x

# import variables and functions
DIR=/usr/bin

# Don't alter the import order
echo ::group::source files
. "$DIR"/global-variables.sh
. "$DIR"/util-methods.sh
. "$DIR"/git-api.sh
#. "$DIR"/workflow.sh
echo ::endgroup::

# Parse Environment Variables
echo ::group::parse_env
parse_env
echo ::endgroup::

export PR_NUMBER=$(jq -r ".pull_request.number" "$GITHUB_EVENT_PATH")

echo ::group::GITHUB_EVENT_PATH
echo "[Warning] GITHUB_EVENT_PATH: $GITHUB_EVENT_PATH"
echo "============================================="
cat "$GITHUB_EVENT_PATH"
echo "============================================="
echo ::endgroup::

if [ "x$INPUT_STAGE" == "x" ]; then
	echo "[Error] INPUT_STAGE is not set";
	set
	exit 1
fi

if [ "$PR_NUMBER" == "null" ]; then
	echo "[Error] Cannot find Pull Request number from GitHub event!"
	exit 1
fi

#export REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "###############################################################"
echo "## Collecting information about Pull Request #${PR_NUMBER}"
echo "###############################################################"

# allow us to handle multiple events: we just need the PR number
export PR_STATE_PATH=${HOME}/pr_state.${PR_NUMBER}.json
curl -X GET -s -H "${AUTH_HEADER}" -H "${API_HEADER}" \
          "${URI}/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" \
          -o $PR_STATE_PATH

echo ::group::PR_STATE_PATH
echo "[Warning] PR_STATE_PATH: $PR_STATE_PATH"
echo "============================================="
cat $PR_STATE_PATH
echo "============================================="
echo ::endgroup::

echo "## Setting variables"
# values from PR_STATE_PATH
export TARGET_BRANCH=$(jq -r ".base.ref" "$PR_STATE_PATH")
export HEAD_SHA=$(jq -r ".head.sha" "$PR_STATE_PATH")
export HEAD_REPO=$(jq -r .head.repo.full_name "$PR_STATE_PATH")
export HEAD_BRANCH=$(jq -r .head.ref "$PR_STATE_PATH")
export GIT_WORK_TREE=$PWD

# values from GITHUB_EVENT_PATH
action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")

echo "###############################################################"
echo "# Workflow Action:   $action"
echo "# GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "# TARGET_BRANCH:     $TARGET_BRANCH"
echo "# HEAD_SHA:          $HEAD_SHA"
echo "# HEAD_REPO:         $HEAD_REPO"
echo "# HEAD_BRANCH:       $HEAD_BRANCH"
echo "# GIT_WORK_TREE:     $GIT_WORK_TREE"
echo "# Conclusion:        $WORKFLOW_CONCLUSION" # neutral, success, cancelled, timed_out, failure
echo "# Perl Version:     " $(perl -E 'say $]')
echo "###############################################################"

set -e -xo pipefail

git config --global user.email "actions@github.com"
git config --global user.name  "GitHub Play Action"

git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git
git remote add       fork https://x-access-token:$COMMITTER_TOKEN@github.com/$HEAD_REPO.git

# rename TARGET_BRANCH -> BASE_BRANCH
git fetch origin $TARGET_BRANCH
git fetch fork   $HEAD_BRANCH

# make sure we are on the branch
git checkout -b pr_${PR_NUMBER} fork/$HEAD_BRANCH
# download the entire commit history as the original clone is done with --depth 1
git pull --unshallow 

set -e +x

echo ::group::git status + log

echo "### git status"
git status

echo "### git log HEAD"
git log --pretty=oneline --abbrev-commit -5

echo "### git log fork/$HEAD_BRANCH"
git log --pretty=oneline --abbrev-commit -5 fork/$HEAD_BRANCH

echo "### git log origin/$TARGET_BRANCH"
git log --pretty=oneline --abbrev-commit -5 origin/$TARGET_BRANCH 

echo ::endgroup::

set -e -x

# echo "## REBASE"
# git rebase origin/$TARGET_BRANCH
#git push --force-with-lease fork $HEAD_BRANCH

# https://github.com/cirrus-actions/rebase/blob/master/entrypoint.sh
# https://github.com/lots0logs/gh-action-auto-merge/blob/master/entrypoint.sh

# pull_request.review.state: approved
# "event_name": "pull_request_review",

/action/run.pl --stage $INPUT_STAGE --action $action

echo "=== END ==="
