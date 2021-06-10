#!/usr/bin/env bash

BASE_URL="https://circleci.com/api/v2"
COMPANY=
PROJECT=
VCS="gh"
METHOD=
BRANCH=
PIPELINE_ID=
PIPELINE_NUMBER=

function check_arg() {
	if [ -z $1 ]; then
		print_usage
	fi
}

function print_usage() {
    cat <<EOH
Usage: $0 -p <project> -b <branch> -c <company> -m <method> -i <pipeline_id> [-v --vcs <version control>]

Where:
    - project:           Name of your project
    - branch:            Name of git branch
    - company:           Name of company
    - version control:   Version control, defaults to github
    - method:            The method to call: get_branch_pipeline, get_latest_workflow
		- pipeline id:       String id of pipeline

Additional:
    - 'CIRCLE_TOKEN' must be set to authorise api calls to circleci
EOH
exit 0
}

function get_args() {
	POSITIONAL=()
	while [[ $# -gt 0 ]]
	do
	key="$1"

	case $key in
			-i|--pipeline_id)
			PIPELINE_ID="$2"
			shift
			shift
			;;
			-p|--project)
			PROJECT="$2"
			shift # past argument
			shift # past value
			;;
			-c|--company)
			COMPANY="$2"
			shift
			shift
			;;
			-b|--branch)
			BRANCH="$2"
			shift
			shift
			;;
			-m|--method)
			METHOD="$2"
			shift
			shift
			;;
			--default)
			DEFAULT=YES
			shift # past argument
			;;
			*)    # unknown option
			POSITIONAL+=("$1") # save it in an array for later
			shift # past argument
			;;
	esac
	done
	check_arg $BRANCH
	check_arg $PROJECT
	check_arg $COMPANY
}

function get_branch_pipeline() {
	curl -s \
		--url "$BASE_URL/project/$VCS/$COMPANY/$PROJECT/pipeline?branch=$BRANCH" \
		--header "Circle-Token: $CIRCLE_TOKEN"
}

function get_latest_workflow() {
	curl -s \
		url "$BASE_URL/pipeline/$PIPELINE_ID/workflow" \
		--header "Circle-Token: $CIRCLE_TOKEN"
}

function call_method() {
	case $1 in
		"get_latest")
		get_latest
		;;
		"get_workflow_status")
		get_workflow_status
		;;
		default)
		echo "No method: '$1' found"
	esac
}

function execute() {
	check_arg $CIRCLE_TOKEN
	get_args $@
	call_method $METHOD
}

execute $@
