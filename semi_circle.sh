#!/usr/bin/env bash

BASE_URL="https://circleci.com/api/v2"
COMPANY=
PROJECT=
VCS="gh"
METHOD=
BRANCH=
PIPELINE_ID=
PIPELINE_NUMBER=
PROJECT_SLUG=

function check_circle_token() {
    if [ -z $CIRCLE_TOKEN ]; then
        echo "'CIRCLE_TOKEN must be set'"
        exit 1
    fi
}

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
    PROJECT_SLUG="$VCS/$COMPANY/$PROJECT"
}

function get_my_branch_pipeline() {
    : '
        Return first page of your pipelines for branch
    '
    curl -s \
        --url "$BASE_URL/project/$PROJECT_SLUG/pipeline/mine?branch=$BRANCH" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function get_branch_pipeline() {
    : '
        Return first page of pipelines for branch
    '
    curl -s \
        --url "$BASE_URL/project/$PROJECT_SLUG/pipeline?branch=$BRANCH" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function get_workflow() {
    : '
        Return specific information about workflow for a unique pipeline id
    '
    curl -s \
        --url "$BASE_URL/pipeline/$PIPELINE_ID/workflow" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function call_method() {
    : '
        Execute method from comand line
    '
    case $1 in
        "get_workflow")
        get_workflow
        exit 0
        ;;
        "get_branch_pipeline")
        get_branch_pipeline
        exit 0
        ;;
        "get_my_branch_pipeline")
        get_my_branch_pipeline
        exit 0
        ;;
        *)
        echo '{"error": "No method:' "$1" 'found" }'
    esac
}

function execute() {
    check_circle_token
    get_args $@
    call_method $METHOD
}

execute $@
