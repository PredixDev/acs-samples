#!/usr/bin/env bash

unset NON_INTERACTIVE_MODE
unset CI_MODE

while getopts ':nj' option; do
    case "$option" in
        n)
            NON_INTERACTIVE_MODE=true
            ;;
        j)
            CI_MODE=true
            ;;
    esac
done

echo -e '\nThis script will deprovision ACS and UAA service instances used by the ACS sample application, as well as the sample application itself\n'

if [ -z "$NON_INTERACTIVE_MODE" ]; then
    read -p 'Press enter to confirm, Ctrl-C to exit'
    echo ''
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ENV_VAR_FILE="${DIR}/.env_vars"
UAA_INSTANCE_NAME=$(grep '^UAA_INSTANCE_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
ACS_INSTANCE_NAME=$(grep '^ACS_INSTANCE_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
ALARMS_APP_NAME=$(grep '^ALARMS_APP_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)

if [[ -z "$UAA_INSTANCE_NAME" || -z "$ACS_INSTANCE_NAME" || -z "$ALARMS_APP_NAME" ]]; then
    echo 'Please run provision.sh prior to running this script'
    exit 2
fi

{ set -x; } 2> /dev/null

# Remove service instances
cf unbind-service "$ALARMS_APP_NAME" "$ACS_INSTANCE_NAME"
cf delete-service "$ACS_INSTANCE_NAME" -f
cf unbind-service "$ALARMS_APP_NAME" "$UAA_INSTANCE_NAME"
cf delete-service "$UAA_INSTANCE_NAME" -f

# Remove the sample application
cf delete "$ALARMS_APP_NAME" -f -r

{ set +x; } 2> /dev/null

if [ -z "$CI_MODE" ]; then
    cf delete-orphaned-routes -f
fi

rm -f "$ENV_VAR_FILE" "${DIR}/alarms-manifest.yml"
