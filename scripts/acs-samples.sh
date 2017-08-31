#!/usr/bin/env bash

set -e

ROOT_DIR="$quickstartRootDir"
LOG_DIR="${ROOT_DIR}/log"

# Be sure to set all your variables in the variables.sh file before you run quick start!
source "${ROOT_DIR}/bash/scripts/variables.sh"
source "${ROOT_DIR}/bash/scripts/error_handling_funcs.sh"
source "${ROOT_DIR}/bash/scripts/files_helper_funcs.sh"
source "${ROOT_DIR}/bash/scripts/curl_helper_funcs.sh"
source "${ROOT_DIR}/bash/scripts/predix_funcs.sh"
source "${ROOT_DIR}/bash/scripts/quickstart-acs-samples-functions.sh"

trap trap_ctrlc INT

if [[ ! -d "$LOG_DIR" ]]; then
    mkdir "$LOG_DIR"
    chmod 0744 "$LOG_DIR"
fi
touch "${LOG_DIR}/quickstart.log"

__validate_num_arguments 1 "$#" "'$(echo $0 | xargs basename)' expected in order: none" "$LOG_DIR"
__append_new_head_log 'Build & Deploy Application' '#' "$LOG_DIR"

function execute_maven_script() {
    local MAVEN_SCRIPT="$1"
    if [[ -n "$MVN_SETTINGS_FILE_LOC" ]]; then
        MAVEN_SCRIPT="export JVM_PROXY_OPTS=\"-Dhttp.proxyHost='$(get_proxy_host "$http_proxy")' -Dhttp.proxyPort='$(get_proxy_port "$http_proxy")' -Dhttps.proxyHost='$(get_proxy_host "$https_proxy")' -Dhttps.proxyPort='$(get_proxy_port "$https_proxy")'\" && ${MAVEN_SCRIPT} -s ${MVN_SETTINGS_FILE_LOC}"
    else
        MAVEN_SCRIPT="unset JVM_PROXY_OPTS && ${MAVEN_SCRIPT}"
    fi
    eval "$MAVEN_SCRIPT"
}

function main() {
    pushd "${ROOT_DIR}/acs-samples/spring-mvc-api" > /dev/null 2>&1
    ./provision.sh -n
    execute_maven_script './push-sample-app.sh -n'
    execute_maven_script './run-integration-tests.sh -n'
    popd > /dev/null 2>&1
}