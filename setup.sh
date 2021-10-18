#!/usr/bin/env bash

REALPATH=$(which realpath)
if [ -z $REALPATH ]; then
  realpath() {
    [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
  }
fi
# Set up constants
SCRIPT_PATH=$(realpath $(dirname "$0"))
TERRAFORM=$(which terraform)
cd $SCRIPT_PATH
# Load .env file source is exist
if [ -f ./.env ]; then
  source ./.env
else
  echo ".env file is missing. Cant continue"
  exit 200
fi

# Load env variables
export TF_VAR_access_key=${AWS_ACCESS_KEY_ID:-not-set}
export TF_VAR_secret_key=${AWS_SECRET_ACCESS_KEY:-not-set}
export TF_VAR_region=${AWS_DEFAULT_REGION:-not-set}
export SCRIPT_COMMIT=${SCRIPT_COMMIT:-false}
export SCRIPT_INIT=${SCRIPT_INIT:-false}
export SCRIPT_PLAN=${SCRIPT_PLAN:-false}
export SCRIPT_DESTROY=${SCRIPT_DESTROY:-false}

# Sanity checks
if [ -z "$TERRAFORM" ]; then
  echo "Missing terraform binary"
  exit 2
fi

# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
  set -o xtrace # Trace the execution of the script (debug)
fi

# A better class of script...
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline

# DESC: Usage help
# ARGS: None
# OUTS: None
function script_usage() {
  cat <<EOF
Usage:
     ---commit                  Apply terrafrom code
     --init                     Init terrafrom code
     --plan                     Plan terrafrom code
     --destroy                  Destroy resources
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
EOF
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parse_params() {
  local param
  while [[ $# -gt 0 ]]; do
    param="$1"
    shift
    case $param in
    --commit)
      export SCRIPT_COMMIT=true
      ;;
    --init)
      export SCRIPT_INIT=true
      ;;
    --plan)
      export SCRIPT_PLAN=true
      ;;
    --destroy)
      export SCRIPT_DESTROY=true
      ;;
    -h | --help)
      script_usage
      exit 0
      ;;
    -v | --verbose)
      verbose=true
      ;;
    *)
      echo "Invalid parameter was provided: $param"
      exit 1
      ;;
    esac
  done
}

# DESC: Plan terrafrom resources
# ARGS: None
# OUTS: None
function terraform_plan() {
  # Format code
  ${TERRAFORM} fmt

  ## Initialize terraform
  ${TERRAFORM} plan

}

# DESC: Commit terrafrom resources
# ARGS: None
# OUTS: None
function terraform_commit() {

  terraform_plan

  ## Create the resource
  ${TERRAFORM} apply -auto-approve

  ## View state file
  ${TERRAFORM} show

}

# DESC: Init terrafrom resources
# ARGS: None
# OUTS: None
function terraform_init() {
  # Format code
  # ${TERRAFORM} fmt
  echo "Init S3"
  cd $SCRIPT_PATH/terraform_init/S3
  $TERRAFORM init
  terraform_commit

  echo "Init DynamoDB"
  cd $SCRIPT_PATH/terraform_init/DynamoDB
  $TERRAFORM init
  terraform_commit

  echo "Init Lampstack"
  cd $SCRIPT_PATH
  ## Initialize terraform
  ${TERRAFORM} init

}

# DESC: Destroy terrafrom resources
# ARGS: None
# OUTS: None
function terraform_destroy() {
  # Format code
  ${TERRAFORM} fmt

  # Destroy the resources
  ${TERRAFORM} destroy

}

# DESC: Main script function
# ARGS: command line params
# OUTS: None
function main() {

  parse_params "$@"

  if [ "${SCRIPT_INIT}" == "true" ]; then
    terraform_init
    exit 0
  fi

  if [ "${SCRIPT_COMMIT}" == "true" ]; then
    terraform_commit
    exit 0
  fi

  if [ "${SCRIPT_PLAN}" == "true" ]; then
    terraform_plan
    exit 0
  fi

  if [ "${SCRIPT_DESTROY}" == "true" ]; then
    terraform_destroy
    exit 0
  fi

}

main "$@"
