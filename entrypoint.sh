#!/bin/bash

set -e +x

echo ::group::GITHUB_EVENT_PATH
echo "[Warning] GITHUB_EVENT_PATH: $GITHUB_EVENT_PATH"
echo "============================================="
cat "$GITHUB_EVENT_PATH"
echo "============================================="
echo ::endgroup::

# input arguments

# setting it is not really needed
#INPUT_STAGE="$1"
if [ "x$INPUT_STAGE" == "x" ]; then
	echo "[Error] INPUT_STAGE is not set";
	set
	exit 1
fi

export GIT_WORK_TREE=$PWD

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")

echo "perl -cw"
perl -cw /action/run.pl ||:

echo "# RUN: /action/run.pl --stage $INPUT_STAGE --event-action $action"
/action/run.pl --stage $INPUT_STAGE --event-action $action

echo "=== Next CI Action DONE ==="
