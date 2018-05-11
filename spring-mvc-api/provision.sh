#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/quickstart-acs-samples-functions.sh"

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

function get_token {
    local UAA_ADMIN_TOKEN=$(
        curl -s \
             -X POST \
             -H 'Content-Type: application/x-www-form-urlencoded' \
             -d "client_id=${1}&client_secret=${2}&grant_type=client_credentials&response_type=token" \
             "${UAA_URL}/oauth/token" | \
        python -c "import sys, json; print json.load(sys.stdin)['access_token']" 2> /dev/null
    )
    echo "$UAA_ADMIN_TOKEN"
}

function add_client {
    local BODY="\"client_id\" : \"${1}\", \"client_secret\" : \"${2}\", \"scope\" : [ ${3} ], \"authorized_grant_types\" : [ ${4} ], \"authorities\" : [ ${5} ]"
    if [[ -n "$6" ]]; then
        BODY="${BODY}, \"redirect_uri\" : [ ${6} ], \"allowedproviders\" : [ \"uaa\" ]"
    fi
    BODY="{ ${BODY} }"
    curl -s \
         -X POST \
         -H "Authorization: Bearer $UAA_ADMIN_TOKEN" \
         -H 'Content-Type: application/json' \
         -d "$BODY" \
         "${UAA_URL}/oauth/clients" > /dev/null 2>&1
}

function add_group {
    local GROUP_ID=$(
        curl -s \
             -X POST \
             -H "Authorization: Bearer $UAA_ADMIN_TOKEN" \
             -H 'Content-Type: application/json' \
             -d "{ \"displayName\" : \"${1}\" }" \
             "${UAA_URL}/Groups" | \
        python -c "import sys, json; print json.load(sys.stdin)['id']" 2> /dev/null
    )
    echo "$GROUP_ID"
}

function add_user {
    local USER_ID=$(
        curl -s \
             -X POST \
             -H "Authorization: Bearer $UAA_ADMIN_TOKEN" \
             -H 'Content-Type: application/json' \
             -d "{ \"userName\" : \"${1}\", \"password\" : \"${2}\", \"emails\" : [ { \"value\" : \"${3}\", \"primary\" : true } ] }" \
             "${UAA_URL}/Users" | \
        python -c "import sys, json; print json.load(sys.stdin)['id']" 2> /dev/null
    )
    echo "$USER_ID"
}

function add_member {
    curl -s \
         -X POST \
         -H "Authorization: Bearer $UAA_ADMIN_TOKEN" \
         -H 'Content-Type: application/json' \
         -d "{ \"origin\" : \"uaa\", \"type\" : \"USER\", \"value\" : \"${2}\" }" \
         "${UAA_URL}/Groups/${1}/members" > /dev/null 2>&1
}

echo -e '\nProvisioning all prerequisites for the ACS sample application...\n'

if [ -z "$NON_INTERACTIVE_MODE" ]; then
    read -p 'Press enter to confirm, Ctrl-C to exit'
    echo ''
fi

CMD_EXIT_STATUS=$(cf t > /dev/null 2>&1; echo "$?")
if [ "$CMD_EXIT_STATUS" -ne 0 ]; then
    echo "No CF org/space targeted. Please login to CF prior to running this script (e.g. cf login -a 'https://api.system.aws-usw02-pr.ice.predix.io')."
    exit 1
fi

# Change these environment variables if you know what you're doing
UAA_SERVICE_ID=predix-uaa
UAA_INSTANCE_NAME=acs-sample-uaa
UAA_PLAN_NAME=Free
ACS_SERVICE_ID=predix-acs
ACS_INSTANCE_NAME=acs-sample-instance
ACS_PLAN_NAME=Free

if [ -n "$CI_MODE" ]; then
    CF_DOMAIN=run.aws-usw02-dev.ice.predix.io
else
    CF_DOMAIN=run.aws-usw02-pr.ice.predix.io
fi

# Create an instance of the UAA service
SECRET_SUFFIX='-secret'
UAA_ADMIN_SECRET="admin${SECRET_SUFFIX}"
cf cs "$UAA_SERVICE_ID" "$UAA_PLAN_NAME" "$UAA_INSTANCE_NAME" -c '{ "adminClientSecret" : "'${UAA_ADMIN_SECRET}'" }'
UAA_INSTANCE_GUID=$(cf service --guid $UAA_INSTANCE_NAME)
UAA_URL="https://${UAA_INSTANCE_GUID}.${UAA_SERVICE_ID}.${CF_DOMAIN}"

# Create an instance of the ACS service
cf cs "$ACS_SERVICE_ID" "$ACS_PLAN_NAME" "$ACS_INSTANCE_NAME" -c '{ "trustedIssuerIds" : "'${UAA_URL}/oauth/token'" }'
ACS_INSTANCE_GUID=$(cf service --guid $ACS_INSTANCE_NAME)

ENV_VAR_FILE="${DIR}/.env_vars"
echo "CF_DOMAIN=${CF_DOMAIN}" > "$ENV_VAR_FILE"
echo "UAA_INSTANCE_NAME=${UAA_INSTANCE_NAME}" >> "$ENV_VAR_FILE"
echo "ACS_INSTANCE_NAME=${ACS_INSTANCE_NAME}" >> "$ENV_VAR_FILE"

# Do not change these environment variables
USER_PASSWORD='p@55WOrd'

ALARMS_APP_NAME=acs-sample-alarm
echo "ALARMS_APP_NAME=${ALARMS_APP_NAME}" >> "$ENV_VAR_FILE"

ALARMS_CLIENT_APP_NAME=alarms-app
ALARMS_CLIENT_APP_SECRET="${ALARMS_CLIENT_APP_NAME}${SECRET_SUFFIX}"
ALARMS_POLICY_CLIENT_APP_NAME=alarms-policy-app
ALARMS_POLICY_CLIENT_APP_SECRET="${ALARMS_POLICY_CLIENT_APP_NAME}${SECRET_SUFFIX}"
ALARMS_ADMIN_NAME=alarms-admin
ALARMS_ADMIN_PASSWORD="$USER_PASSWORD"
ALARMS_POLICY_ADMIN_NAME=alarms-policy-admin
ALARMS_POLICY_ADMIN_PASSWORD="$USER_PASSWORD"
ALARMS_USER_NAME=alarms-user
ALARMS_USER_PASSWORD="$USER_PASSWORD"
POLICIES_GROUP_NAME_READ=acs.policies.read
POLICIES_GROUP_NAME_WRITE=acs.policies.write
ATTRIBUTES_GROUP_NAME_READ=acs.attributes.read
ATTRIBUTES_GROUP_NAME_WRITE=acs.attributes.write
ACS_GROUP_NAME="${ACS_SERVICE_ID}.zones.${ACS_INSTANCE_GUID}.user"

# Get a token from UAA
UAA_ADMIN_TOKEN=$(get_token 'admin' "$UAA_ADMIN_SECRET")

# Upsert the alarms policy app client
add_client \
    "$ALARMS_POLICY_CLIENT_APP_NAME" \
    "$ALARMS_POLICY_CLIENT_APP_SECRET" \
    "\"$ATTRIBUTES_GROUP_NAME_READ\", \"$ATTRIBUTES_GROUP_NAME_WRITE\", \"$POLICIES_GROUP_NAME_READ\", \"$POLICIES_GROUP_NAME_WRITE\", \"$ACS_GROUP_NAME\", \"uaa.resource\"" \
    "\"client_credentials\", \"password\", \"refresh_token\"" \
    "\"$ATTRIBUTES_GROUP_NAME_READ\", \"$ATTRIBUTES_GROUP_NAME_WRITE\", \"$POLICIES_GROUP_NAME_READ\", \"$POLICIES_GROUP_NAME_WRITE\", \"$ACS_GROUP_NAME\", \"uaa.resource\""

# Upsert the alarms app client
add_client \
    "$ALARMS_CLIENT_APP_NAME" \
    "$ALARMS_CLIENT_APP_SECRET" \
    "\"$ACS_GROUP_NAME\", \"uaa.resource\"" \
    "\"password\", \"refresh_token\", \"authorization_code\"" \
    "\"$ACS_GROUP_NAME\"" \
    '"http://localhost:9000/callback"'

# Create the UAA groups needed for ACS
POLICIES_GROUP_ID_READ=$(add_group "$POLICIES_GROUP_NAME_READ")
POLICIES_GROUP_ID_WRITE=$(add_group "$POLICIES_GROUP_NAME_WRITE")
ATTRIBUTES_GROUP_ID_READ=$(add_group "$ATTRIBUTES_GROUP_NAME_READ")
ATTRIBUTES_GROUP_ID_WRITE=$(add_group "$ATTRIBUTES_GROUP_NAME_WRITE")
ACS_GROUP_ID=$(add_group "$ACS_GROUP_NAME")

# Create the alarms policy admin user
ALARMS_POLICY_ADMIN_ID=$(add_user "$ALARMS_POLICY_ADMIN_NAME" "$ALARMS_POLICY_ADMIN_PASSWORD" "${ALARMS_POLICY_ADMIN_NAME}@example.com")

# Update authorities for the alarms policy admin user
add_member "$POLICIES_GROUP_ID_READ" "$ALARMS_POLICY_ADMIN_ID"
add_member "$POLICIES_GROUP_ID_WRITE" "$ALARMS_POLICY_ADMIN_ID"
add_member "$ATTRIBUTES_GROUP_ID_READ" "$ALARMS_POLICY_ADMIN_ID"
add_member "$ATTRIBUTES_GROUP_ID_WRITE" "$ALARMS_POLICY_ADMIN_ID"
add_member "$ACS_GROUP_ID" "$ALARMS_POLICY_ADMIN_ID"

# Create the alarms user
ALARMS_USER_ID=$(add_user "$ALARMS_USER_NAME" "$ALARMS_USER_PASSWORD" "${ALARMS_USER_NAME}@example.com")
add_member "$ACS_GROUP_ID" "$ALARMS_USER_ID"

# Create the alarms admin user
ALARMS_ADMIN_ID=$(add_user "$ALARMS_ADMIN_NAME" "$ALARMS_ADMIN_PASSWORD" "${ALARMS_ADMIN_NAME}@example.com")
add_member "$ACS_GROUP_ID" "$ALARMS_ADMIN_ID"

append_to_quickstart_summary "Provisioned a UAA instance for use by the ACS sample application. You can now obtain access tokens from it using the following URL: ${UAA_URL}/oauth/token"

SAMPLE_APP_VERSION=$(grep -A 1 '<artifactId>acs-samples</artifactId>' "${DIR}/pom.xml" | grep '<version>' | sed 's/^.*<version>\(.*\)<\/version>.*$/\1/')

# Generate the sample application manifest YAML file
YAML_FILE_NAME='alarms-manifest.yml'

echo "YAML_FILE_NAME=${YAML_FILE_NAME}" >> "$ENV_VAR_FILE"
echo "ALARMS_CLIENT_APP_NAME=${ALARMS_CLIENT_APP_NAME}" >> "$ENV_VAR_FILE"
echo "ALARMS_CLIENT_APP_SECRET=${ALARMS_CLIENT_APP_SECRET}" >> "$ENV_VAR_FILE"
echo "ALARMS_ADMIN_NAME=${ALARMS_ADMIN_NAME}" >> "$ENV_VAR_FILE"
echo "ALARMS_ADMIN_PASSWORD=${ALARMS_ADMIN_PASSWORD}" >> "$ENV_VAR_FILE"
echo "ALARMS_USER_NAME=${ALARMS_USER_NAME}" >> "$ENV_VAR_FILE"
echo "ALARMS_USER_PASSWORD=${ALARMS_USER_PASSWORD}" >> "$ENV_VAR_FILE"

cat << EOF > "${DIR}/${YAML_FILE_NAME}"
---
# Manifest for ACS DEMO. Properties can be overridden from the command line. This file can be used for manual cf push.
applications:
- name: $ALARMS_APP_NAME
  path: target/acs-springmvc-api-sample-${SAMPLE_APP_VERSION}.jar
  memory: 512M
  instances: 1
  services:
  - $UAA_INSTANCE_NAME
  - $ACS_INSTANCE_NAME
  env:
    SPRING_PROFILES_ACTIVE: cloud
    UAA_INSTANCE_NAME: $UAA_INSTANCE_NAME
    ACS_INSTANCE_NAME: $ACS_INSTANCE_NAME
    ALARMS_POLICY_CLIENT_APP_NAME: $ALARMS_POLICY_CLIENT_APP_NAME
    ALARMS_POLICY_CLIENT_APP_SECRET: $ALARMS_POLICY_CLIENT_APP_SECRET
    ALARMS_POLICY_ADMIN_NAME: $ALARMS_POLICY_ADMIN_NAME
    ALARMS_POLICY_ADMIN_PASSWORD: $ALARMS_POLICY_ADMIN_PASSWORD
    ALARMS_ADMIN_NAME: $ALARMS_ADMIN_NAME
    ALARMS_USER_NAME: $ALARMS_USER_NAME
EOF

if [ -z "$NON_INTERACTIVE_MODE" ]; then
    echo ''
    read -p 'Provisioning complete. Would you like to push the sample application to your Cloud Foundry org/space? [y/n]: ' PUSH_SAMPLE_APP

    if [[ "$PUSH_SAMPLE_APP" == 'y' || "$PUSH_SAMPLE_APP" == 'Y' || "$PUSH_SAMPLE_APP" == 'yes' ]]; then
        "${DIR}/push-sample-app.sh"
    fi
fi
