#!/bin/bash

set -e +x

echo "::group::GITHUB_EVENT_PATH: $GITHUB_EVENT_PATH"
echo "============================================="
cat "$GITHUB_EVENT_PATH"
echo "============================================="
echo ::endgroup::

echo "::group::ENV"
echo "============================================="
set
echo "============================================="
echo ::endgroup::

echo "::group::Check Tokens"
echo "============================================="
perl -E 'say "GITHUB_TOKEN => ", length($ENV{GITHUB_TOKEN} // "")'
perl -E 'say "BOT_ACCESS_TOKEN => ", length($ENV{BOT_ACCESS_TOKEN} // "")'
echo "============================================="
echo ::endgroup::

# input arguments

# setting it is not really needed
#INPUT_STAGE="$1"
if [ "x$INPUT_STAGE" == "x" ]; then
	echo "[Error] INPUT_STAGE is not set";	
	exit 1
fi

export GIT_WORK_TREE=$PWD

export PR_NUMBER=$(jq -r ".pull_request.number" "$GITHUB_EVENT_PATH")
action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")

echo "# perl -cw"
perl -cw /action/run.pl ||:

echo "# RUN: /action/run.pl --stage $INPUT_STAGE --event-action $action"
/action/run.pl --stage $INPUT_STAGE --event-action $action

echo "=== Next CI Action DONE ==="
