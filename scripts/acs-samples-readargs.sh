#!/usr/bin/env bash

set -e

function __print_out_usage() {
    echo -e 'Usage:\n'
    echo -e "./${SCRIPT_NAME}\n"
}

# Reset all variables that might be set
PRINT_USAGE=0
LOGIN=1
#RUN_CREATE_UAA=1
#RUN_CREATE_ACS=1

function processReadargs() {
    printCommonVariables
}
