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
        addComment $PR_NUMBER "Clean PR from Maintainer merging to p5 branch"
        git tag current_pr_to_merge
        git checkout -b p5 origin/p5
        git merge current_pr_to_merge --no-edit
        git push origin p5
        # PR should be auto closed...
    else
        addComment $PR_NUMBER "Requesting Code Review from maintainers"
    fi
}