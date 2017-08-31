#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/quickstart-acs-samples-functions.sh"

function usage {
    echo "Usage: ./$( basename "$( python -c "import os; print os.path.abspath('${BASH_SOURCE[0]}')" )" ) [-s <maven_settings_file>]"
}

unset MVN_SETTINGS_FILE_LOC
unset NON_INTERACTIVE_MODE

while getopts ':s:n' option; do
    case "$option" in
        s)
            export MVN_SETTINGS_FILE_LOC="$OPTARG"
            ;;
        n)
            NON_INTERACTIVE_MODE=true
            ;;
        '?' | ':')
            usage
            exit 2
            ;;
    esac
done

echo -e '\nRunning integration tests against the ACS sample application deployed to the cloud...\n'

if [ -z "$NON_INTERACTIVE_MODE" ]; then
    read -p 'Press enter to confirm, Ctrl-C to exit'
    echo ''
fi

ENV_VAR_FILE="${DIR}/.env_vars"
CF_DOMAIN=$(grep '^CF_DOMAIN=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
UAA_INSTANCE_NAME=$(grep '^UAA_INSTANCE_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_APP_NAME=$(grep '^ALARMS_APP_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_CLIENT_APP_NAME=$(grep '^ALARMS_CLIENT_APP_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_CLIENT_APP_SECRET=$(grep '^ALARMS_CLIENT_APP_SECRET=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_ADMIN_NAME=$(grep '^ALARMS_ADMIN_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_ADMIN_PASSWORD=$(grep '^ALARMS_ADMIN_PASSWORD=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_USER_NAME=$(grep '^ALARMS_USER_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
export ALARMS_USER_PASSWORD=$(grep '^ALARMS_USER_PASSWORD=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)

if [[ -z "$CF_DOMAIN" || \
      -z "$UAA_INSTANCE_NAME" || \
      -z "$ALARMS_APP_NAME" || \
      -z "$ALARMS_CLIENT_APP_NAME" || \
      -z "$ALARMS_CLIENT_APP_SECRET" || \
      -z "$ALARMS_ADMIN_NAME" || \
      -z "$ALARMS_ADMIN_PASSWORD" || \
      -z "$ALARMS_USER_NAME" || \
      -z "$ALARMS_USER_PASSWORD" ]]; then
    echo 'Please run provision.sh prior to running this script'
    exit 2
fi

export SAMPLE_URL="https://$(cf app $ALARMS_APP_NAME | grep '^\(urls\|routes\):' | awk '{print $2}')"
export UAA_ISSUER_ID="https://$(cf service --guid $UAA_INSTANCE_NAME).$(cf service $UAA_INSTANCE_NAME | grep '^Service:' | awk '{print $2}').${CF_DOMAIN}/oauth/token"

MVN_COMMAND='set -x; mvn verify -B -D skipTests=false'
if [ -n "$MVN_SETTINGS_FILE_LOC" ]; then
    MVN_COMMAND="${MVN_COMMAND} -s ${MVN_SETTINGS_FILE_LOC}"
fi

{ set -e; } 2> /dev/null
eval "$MVN_COMMAND"

{ set +x; } 2> /dev/null
append_to_quickstart_summary 'Ran integration tests against the ACS sample application in Cloud Foundry.'
