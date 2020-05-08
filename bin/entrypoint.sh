#!/bin/bash

set -xo pipefail

# import variables and functions
DIR=/usr/bin


# See: https://github.com/koalaman/shellcheck/wiki/SC1090
# Don't alter the import order
# shellcheck disable=SC1091
# shellcheck source=/usr/bin
. "$DIR"/global-variables.sh
# shellcheck disable=SC1091
# shellcheck source=/usr/bin
. "$DIR"/util-methods.sh
# shellcheck disable=SC1091
# shellcheck source=/usr/bin
. "$DIR"/git-api.sh

# Parse Environment Variables
parse_env

echo "$GITHUB_EVENT_PATH"
cat "$GITHUB_EVENT_PATH"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")

if [ "$action" == "labeled" ]; then
	pr_num=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
elif [ "$action" == "submitted" ]; then
	review_state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
	if [ "$review_state" == "approved" ]; then
		pr_num=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")	
	else
		echo "Nothing to do for review $review_state"	
		exit 0
	fi
elif [[ "$action" == "pr-build-success"* ]]; then
	event="pr-build-success"

	IFS=' '
	read -ra actionParts <<< "$action"
	
	pr_num="${actionParts[1]}"
else 
	echo "$action is not supported"
	exit 0
fi
