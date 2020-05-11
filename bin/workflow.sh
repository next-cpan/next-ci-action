#!/bin/bash

set -xo pipefail

function closeOnFailure () {
    # neutral, success, cancelled, timed_out, failure
    if [ "$WORKFLOW_CONCLUSION" != 'success' ] ; then
        addComment $PR_NUMBER "**Automatically closing** the Pull Request on failure: workflow conclusion was **$WORKFLOW_CONCLUSION**"
        closePR $PR_NUMBER
        exit 0
    fi
}

function check_openPullRequest () {

    closeOnFailure # and exit

    # the PR is clean
    local pr_from_maintainer
    pr_from_maintainer=$(isPRFromMaintainer "$PR_NUMBER")

    if [ "$pr_from_maintainer" == true ]; then
        addComment $PR_NUMBER "**Clean PR** from Maintainer merging to $TARGET_BRANCH branch"

        git rebase origin/$TARGET_BRANCH
        git push origin HEAD:$TARGET_BRANCH

        #git checkout -b origin/p5
        #git merge $HEAD_SHA --no-edit
        #git push origin HEAD:p5
        # PR should be auto closed...
    else
        addComment $PR_NUMBER "Needs Code Review from Maintainers"
    fi
}