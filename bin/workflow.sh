#!/bin/bash

set -xo pipefail

function closeOnFailure () {
    # neutral, success, cancelled, timed_out, failure
    if [ "$WORKFLOW_CONCLUSION" != 'success' ] ; then
        addComment $PR_NUMBER "Automatically closing the PR on failure: workflow conclusion was '$WORKFLOW_CONCLUSION'"
        closePR $PR_NUMBER
    fi
}

