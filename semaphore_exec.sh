#!/usr/bin/env bash
source ./semaphore.sh

#defaults
attempts=5


function margs_check {
	if [[ $# -lt $margs ]]; then
        echo "missing mandatory params, see help doc"
	    exit 1 # error
	fi
}


function usage {
    echo -e "usage: $script MANDATORY [OPTION]\n"
}


function example {
    echo -e "example: ./semaphore_exec.sh -p 256 -h my.gitlab.int -t <token>  -b latest"
    echo -e "example: ./semaphore_exec.sh --projectid 256 --hostname lab.technest.int --token spSDuPsyQJmxxKeeWosh  --branch latest"
}


function help {
  usage
    echo -e "MANDATORY:"
    echo -e "  -hostname  VAL  The gitlab hostname"
    echo -e "  -token  VAL  The gitlab token"
    echo -e "  -target_branch  VAL  The gitlab token\n"
    echo -e "OPTIONAL:"
    echo -e "  -projectid        The gitlab project id to check"
    echo -e "  -attempts   VAL  How many attempts to check"
    echo -e "  --help             Prints this help\n"
  example
}

function check_invalid_args {
 [[ -z "${2}" || "${2}" == *[[:space:]]* || "${2}" == -* ]]  && { echo -e "ERROR: Invalid argument $1=$2"; exit 1; }
}

while getopts ":p:a:h:t:b:" opt; do
  case $opt in
    p) check_invalid_args "-p" "$OPTARG" || projectid="$OPTARG";;
    a) check_invalid_args "-a" "$OPTARG" || attempts="$OPTARG";;
    h) check_invalid_args "-h" "$OPTARG" || hostname="$OPTARG";;
    t) check_invalid_args "-t" "$OPTARG" || token="$OPTARG";;
    b) check_invalid_args "-b" "$OPTARG" || branch="$OPTARG";;
   \?) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    :) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
  esac
done

# while [[ $# -gt 0 ]] ; do
#   case $1 in
#     -p | --projectid) projectid="$2" ;;
#     -a | --attempts) attempts="$2" ;;
#     -h | --hostname) hostname="$2" ;;
#     -t | --token) token="$2" ;;
#     -b | --branch) branch="$2" ;;
#     --help) help ;;
#     *) echo -e "Unkown option $1"; help;
#   esac
#   shift
# done


if [[ -z ${token} ]]; then echo "gitlab token is not set, please set one using param -t \"yourtoken\" in order to continue";  exit 1; fi

# exec
echo -e "Checking status of projectId: "${projectid}" ..."
echo -e "Options: attempts=${attempts}, hostname=${hostname}, token=${token}, target_branch=${branch}\n"

#Declare the number of mandatory args
margs=3
margs_check $hostname $token $branch

evaluateBranch $projectid $attempts $hostname $token $branch

