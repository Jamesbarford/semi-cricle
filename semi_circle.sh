#!/usr/bin/env bash

BASE_URL="https://circleci.com/api/v2"
BASE_URL_V1="https://circleci.com/api/v1.1"
VCS="gh"
PROJECT_SLUG=
PIPELINE_ID=
PROJECT=
COMPANY=
METHOD=
BRANCH=
WORKFLOW_ID=
OS=$(uname | awk '{print tolower($0)}')

FMT_BOLD=$(tput bold)
FMT_NORMAL=$(tput sgr0)

function print_usage() {
    cat <<EOH
Usage:
    $0 -p <project> -b <branch> -c <company> -m <method> -i <pipeline_id> [-v <version_control> -h help]

Where:
    ${FMT_BOLD}-p <project>:${FMT_NORMAL}
            Name of your project

    ${FMT_BOLD}-b <branch>:${FMT_NORMAL}
            Name of git branch

    ${FMT_BOLD}-c <company>:${FMT_NORMAL}
            Name of company

    ${FMT_BOLD}-v <version_control>:${FMT_NORMAL}
            Version control, defaults to github -> 'gh'

    ${FMT_BOLD}-i <pipeline_id>:${FMT_NORMAL}
            String id of pipeline  

    ${FMT_BOLD}-m <method>:${FMT_NORMAL}
            The method to call

Methods:
    ${FMT_BOLD}get_branch_pipeline${FMT_NORMAL}
        Usage:
            $0 -p <project> -b <branch> -c <company> -m get_branch_pipeline
        Returns:
            returns latest pipelines as a JSON array for a given branch, project and company
      
    ${FMT_BOLD}get_my_branch_pipeline${FMT_NORMAL}
        Usage:
            $0 -p <project> -b <branch> -c <company> -m get_my_branch_pipeline
        Returns:
            Your latest pipelines as a JSON array

    ${FMT_BOLD}get_workflow${FMT_NORMAL}
        Usage:
            $0 -i <pipeline_id> -m get_workflow
        Returns:
            Workflow in JSON for a given pipeline id, contains the status i.e running, success, failed

    ${FMT_BOLD}cancel_workflow${FMT_NORMAL}
        Usage:
            $0 -w <workflow_id> -m cancel_workflow
        Returns:
            JSON indicating success in the format'{"message": "some value"}'

    ${FMT_BOLD}list_envionment_variables${FMT_NORMAL}
        Usage:
            $0 -p <project> -b <branch> -c <company> -m list_envionment_variables
        Returns:
            List of environment variables with values masked
    
    ${FMT_BOLD}get_my_pipelines${FMT_NORMAL}
        Usage:
            $0 -p <project> -b <branch> -c <company> -m get_my_pipelines
        Returns:
            A list of all your pipelines for a project for every branch you've used/created

    ${FMT_BOLD}poll_workflow${FMT_NORMAL}
        Usage:
            $0 -i <pipeline_id> -m poll_workflow
        Returns:
            Will poll the workflow untill it either succeeds or fails, echoing an update
            NOTE: this does not print JSON to standard out and requires 'jq' to be installed

Additional:
    - ${FMT_BOLD}'CIRCLE_TOKEN'${FMT_NORMAL} must be set to authorise api calls to circleci
EOH
exit 0
}

function check_jq() {
    if [ -z jq ]; then
        echo "'jq' must be installed"
        exit 1
    fi
}

function check_circle_token() {
    if [ -z $CIRCLE_TOKEN ]; then
        echo "'CIRCLE_TOKEN must be set'"
        exit 1
    fi
}

function check_branch() {
    if [ -z $BRANCH ]; then
        echo "-b <branch> must be set"
        exit 1
    fi
}

function check_pipeline_id() {
    if [ -z $PIPELINE_ID ]; then
        echo "-i <pipeline_id> missing"
        exit 1
    fi
}

function check_workflow_id() {
    if [ -z $WORKFLOW_ID ]; then
        echo "-w <workflow_id> missing"
        exit 1
    fi
}

function sys_notify() {
    : '
        Function will make a bell sound in the terminal and fire off a system
        notifcation
    '
    local MSG=$1
    if [[ $OS == *"linux"* ]]; then
        zenity --notification --text "${MSG}"
    fi

    if [[ $OS == *"darwin"* ]]; then
        osascript -e 'display notification "'"${MSG}"'" with title "Circle ci pipeline finished" sound name "Crystal"'
    fi

    tput bel
    echo $MSG
}

function create_slug() {
    local MISSING=()

    if [ -z $PROJECT ]; then
        MISSING+=("-p <project> must be set")
    fi

    if [ -z $COMPANY ]; then
        MISSING+=("-c <company> must be set")
    fi

    if [ ${#MISSING[@]} == 0 ]; then
        PROJECT_SLUG="$VCS/$COMPANY/$PROJECT"
    else
        for MISS in "${MISSING[@]}"; do
            echo $MISS
        done
        exit 1
    fi
}

function get_args() {
    if [ $1 == "-h" ]; then
        print_usage
    fi
    while getopts "h:i:p:c:b:w:m:" ARG; do
        case $ARG in
            i)
                PIPELINE_ID=$OPTARG
            ;;
            p)
                PROJECT=$OPTARG
            ;;
            c)
                COMPANY=$OPTARG
            ;;
            b)
                BRANCH=$OPTARG
            ;;
            m)
                METHOD=$OPTARG
            ;;
            v)
                VCS=$OPTARG
            ;;
            w)
                WORKFLOW_ID=$OPTARG
            ;;
            h)
                print_usage
                exit 0
            ;;
            *)
                echo "Unknown argument: $ARG"
                exit 1
            ;;
        esac
    done
}

function get_my_pipelines() {
    : '
        Return all of your pipelines
    '
    create_slug
    curl -s \
        --url "$BASE_URL/project/$PROJECT_SLUG/pipeline/mine" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function list_envionment_variables() {
    : '
        Returns a list of environment variables for a project
    '
    create_slug
    curl -s \
        --url "$BASE_URL_V1/project/$PROJECT_SLUG/envvar" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function get_my_branch_pipeline() {
    : '
        Return first page of your pipelines for branch
    '
    create_slug
    check_branch
    curl -s \
        --url "$BASE_URL/project/$PROJECT_SLUG/pipeline/mine?branch=$BRANCH" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function get_branch_pipeline() {
    : '
        Return first page of pipelines for branch
    '
    create_slug
    check_branch
    curl -s \
        --url "$BASE_URL/project/$PROJECT_SLUG/pipeline?branch=$BRANCH" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function get_workflow() {
    : '
        Return specific information about workflow for a unique pipeline id
    '
    check_pipeline_id
    curl -s \
        --url "$BASE_URL/pipeline/$PIPELINE_ID/workflow" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function cancel_workflow() {
    : '
        Cancel a workflow using workflow id
    '
    check_workflow_id
    curl -s \
        --url "$BASE_URL/workflow/$WORKFLOW_ID/cancel" \
        --header "Circle-Token: $CIRCLE_TOKEN"
}

function poll_workflow() {
    : '
        Polls workflow until it has either succeeded or failed
    '
    check_jq

    local IS_DONE=0
    while [ $IS_DONE == 0 ]; do
        local RESPONSE=$(get_workflow)
        local STATUS=$(echo $RESPONSE | jq -r '.items[].status')
        local WORKFLOW_NAME=$(echo $RESPONSE | jq -r '.items[].name')
        local WORKFLOW_COUNT=${#RESPONSE[@]}
        local DONE_COUNT=0

        for (( i = 0; i < $WORKFLOW_COUNT; ++i )); do
            echo "Workflow name: ${FMT_BOLD}$WORKFLOW_NAME${FMT_NORMAL}, status: ${FMT_BOLD}$STATUS${FMT_NORMAL}"
            case $STATUS in
                "success")
                    DONE_COUNT=$((DONE_COUNT + 1))
                ;;
                "failing"|"error"|"failed")
                    IS_DONE=1
                    break
                ;;
            esac
            if [ $WORKFLOW_COUNT == $DONE_COUNT ];then
                IS_DONE=1
                break
            fi
        done
        if [ $IS_DONE == 1 ]; then
            break
        fi
        sleep 5
    done

    if [ $WORKFLOW_COUNT == $DONE_COUNT ]; then
        sys_notify "Pipeline success!"
    else
        sys_notify "Pipeline failed"
    fi
}

function call_method() {
    : '
        Execute method from command line
    '
    if [ -z $1 ]; then
        echo "-m <method> must be set"
        exit 1
    fi
    case $1 in
        "get_my_pipelines")
            get_my_pipelines
            exit 0
        ;;
        "get_workflow")
            get_workflow
            exit 0
        ;;
        "cancel_workflow")
            cancel_workflow
            exit 0
        ;;
        "list_envionment_variables")
            list_envionment_variables
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
        "poll_workflow")
            poll_workflow
            exit 0
        ;;
        *)
            echo '{"error": "No method:' "$1" 'found" }'
        ;;
    esac
}

function execute() {
    if [ -z $1 ]; then
        print_usage
    fi
    check_circle_token
    get_args $@
    call_method $METHOD
}

execute $@
