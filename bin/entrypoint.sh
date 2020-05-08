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

echo "$GITHUB_EVENT_PATH"
cat "$GITHUB_EVENT_PATH"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")

/action/run.pl $action
