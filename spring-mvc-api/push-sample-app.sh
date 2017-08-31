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

echo -e '\nBuilding and pushing the ACS sample application to Cloud Foundry...\n'

if [ -z "$NON_INTERACTIVE_MODE" ]; then
    read -p 'Press enter to confirm, Ctrl-C to exit'
    echo ''
fi

ENV_VAR_FILE="${DIR}/.env_vars"
ALARMS_APP_NAME=$(grep '^ALARMS_APP_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)
YAML_FILE_NAME=$(grep '^YAML_FILE_NAME=' "$ENV_VAR_FILE" 2> /dev/null | cut -d '=' -f 2)

if [[ -z "$ALARMS_APP_NAME" || -z "$YAML_FILE_NAME" ]]; then
    echo 'Please run provision.sh prior to running this script'
    exit 2
fi

CMD_EXIT_STATUS=$(cf t > /dev/null 2>&1; echo "$?")
if [ "$CMD_EXIT_STATUS" -ne 0 ]; then
    echo "No CF org/space targeted. Please login to CF prior to running this script (e.g. cf login -a 'https://api.system.aws-usw02-pr.ice.predix.io')."
    exit 1
fi

MVN_COMMAND='set -x; mvn clean install -B'
if [ -n "$MVN_SETTINGS_FILE_LOC" ]; then
    MVN_COMMAND="${MVN_COMMAND} -s ${MVN_SETTINGS_FILE_LOC}"
fi

{ set -e; } 2> /dev/null
eval "$MVN_COMMAND"

cf push -f "${DIR}/${YAML_FILE_NAME}" --random-route

{ set +x; } 2> /dev/null

CF_SAMPLE_APP_ROUTE="https://$(cf app $ALARMS_APP_NAME | grep '^\(urls\|routes\):' | awk '{print $2}')"
append_to_quickstart_summary "Pushed the ACS sample application to Cloud Foundry whose route is: ${CF_SAMPLE_APP_ROUTE} . You can navigate to the following URL in your browser to ensure it's working: ${CF_SAMPLE_APP_ROUTE}/greeting ."

if [ -z "$NON_INTERACTIVE_MODE" ]; then
    echo ''
    read -p 'The ACS sample application has been successfully pushed to Cloud Foundry. Would you like to run integration tests? [y/n]: ' RUN_INT_TESTS

    if [[ "$RUN_INT_TESTS" == 'y' || "$RUN_INT_TESTS" == 'Y' || "$RUN_INT_TESTS" == 'yes' ]]; then
        "${DIR}/run-integration-tests.sh"
    fi
fi
