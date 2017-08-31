#!/usr/bin/env bash

{ set -e; } 2> /dev/null

function local_read_args() {
    while (( "$#" )); do
        case "$1" in
            -h|--help|-\?)
                PRINT_USAGE=1
                QUICKSTART_ARGS="${SCRIPT} ${1}"
                break
                ;;
            -s|--skip-setup)
                SKIP_SETUP='true'
                ;;
            *)
                QUICKSTART_ARGS+=" ${1}"
                ;;
        esac
        shift
    done
}

function check_internet() {
    { set +e; } 2> /dev/null
    echo -e '\nChecking internet connection...'
    curl -k "$1" > /dev/null 2>&1
    if [[ "$?" -ne 0 ]]; then
        echo "Unable to connect to the internet, make sure you're connected to a network and check your proxy settings if you're behind a corporate proxy."
        if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
            read -p "You have either the 'http_proxy' or the 'https_proxy' environment variable set. Would you like to unset them and try again? [y/n] > " ANSWER
            if [[ -z "$ANSWER" ]]; then
                read -p 'Specify [y/n] > ' ANSWER
            fi
            if [[ "${ANSWER:0:1}" == 'y' || "${ANSWER:0:1}" == 'Y' ]]; then
                unset http_proxy
                unset HTTP_PROXY
                unset https_proxy
                unset HTTPS_PROXY
            else
                exit 0
            fi
        else
            read -p "You have neither the 'http_proxy' nor the 'https_proxy' environment variable set. Would you like to set them and try again? [y/n] > " ANSWER
            if [[ -z "$ANSWER" ]]; then
                read -p 'Specify [y/n] > ' ANSWER
            fi
            if [[ "${ANSWER:0:1}" == 'y' || "${ANSWER:0:1}" == 'Y' ]]; then
                read -p "Enter the value for 'http_proxy' (e.g. http://my.company.com:80) > " http_proxy
                if [[ -n "$http_proxy" ]]; then
                    export http_proxy
                    export HTTP_PROXY="$http_proxy"
                fi
                read -p "Enter the value for 'https_proxy' (e.g. https://my.company.com:80) > " https_proxy
                if [[ -n "$https_proxy" ]]; then
                    export https_proxy
                    export HTTPS_PROXY="$https_proxy"
                fi
            else
                exit 0
            fi
        fi
        echo 'Attempting to recheck internet connection...'
        curl -k "$1" > /dev/null 2>&1
        if [[ "$?" -ne 0 ]]; then
            echo 'Still unable to connect to the internet'
            exit 1
        fi
    fi
    echo -e 'OK\n'
    { set -e; } 2> /dev/null
}

function init() {
    check_internet 'https://www.google.com'
    eval "$(curl -s -L 'https://raw.githubusercontent.com/PredixDev/izon/master/izon.sh')"
    getVersionFile
    getLocalSetupFuncs
}

function print_out_standard_usage() {
    echo '**************** Usage ***************************'
    echo "     ./${SCRIPT_NAME}"
    echo '**************************************************'
}

function standard_mac_initialization() {
    echo -e "\nWelcome to the ${APP_NAME} Quick Start."
    print_out_standard_usage
    echo "QUICKSTART_ARGS       : ${QUICKSTART_ARGS}"
    run_mac_setup
    echo -e "\nThe required tools have been installed or you have chosen to not install them. Proceeding with the setting up services and application.\n\n"
}

function generate_maven_proxy_details() {
    local PROXY_DETAILS="$(cat <<EOF
            <host>$(get_proxy_host "$1")</host>
            <port>$(get_proxy_port "$1")</port>
EOF
)"

    local PROXY_USERNAME=$(get_proxy_username "$1")
    if [[ -n "$PROXY_USERNAME" ]]; then
        PROXY_DETAILS="${PROXY_DETAILS}
$(cat <<EOF
            <username>$PROXY_USERNAME</username>
            <password>$(get_proxy_password "$1")</password>
EOF
)"
    fi

    echo "$PROXY_DETAILS"
}

if [[ -n "$HTTP_PROXY" && -z "$http_proxy" ]]; then
    export http_proxy="$HTTP_PROXY"
fi

if [[ -n "$HTTPS_PROXY" && -z "$https_proxy" ]]; then
    export https_proxy="$HTTPS_PROXY"
fi

REPO_NAME='acs-samples'
PRINT_USAGE=0
SKIP_SETUP='false'
SCRIPT="-script ${REPO_NAME}.sh -script-readargs ${REPO_NAME}-readargs.sh"
QUICKSTART_ARGS="$SCRIPT"
VERSION_JSON='version.json'
REPO_BRANCH='master'
GITHUB_URL_PREFIX='https://raw.githubusercontent.com/PredixDev'
VERSION_JSON_URL="${GITHUB_URL_PREFIX}/${REPO_NAME}/${REPO_BRANCH}/${VERSION_JSON}"
PREDIX_SCRIPTS='predix-scripts'
APP_NAME='Access Control Service (ACS) Samples'
TOOLS='Cloud Foundry CLI, Git, Predix CLI'
TOOLS_SWITCHES='--cf --git --predixcli'
SCRIPT_NAME='quickstart-acs-samples.sh'
INSTANCE_PREPENDER='acs-sample'

local_read_args "$@"
init

if [[ "$PRINT_USAGE" == 1 ]]; then
    print_out_standard_usage
fi

if [[ "$SKIP_SETUP" != 'true' ]]; then
    if [[ "$OSTYPE" == 'linux'* && "$(uname -n)" != *'predix-devbox'* ]]; then
        INSTALL_PREREQS_SCRIPT='install-prereqs.sh'
        rm -f "./${INSTALL_PREREQS_SCRIPT}"
        curl -s -O "${GITHUB_URL_PREFIX}/${REPO_NAME}/${REPO_BRANCH}/${INSTALL_PREREQS_SCRIPT}"
        chmod a+x "./${INSTALL_PREREQS_SCRIPT}"
        "./${INSTALL_PREREQS_SCRIPT}"
    elif [[ "$OSTYPE" == 'darwin'* ]]; then
        standard_mac_initialization
    fi
fi

getPredixScripts
getCurrentRepo

PREDIX_SCRIPTS_LOCATION="$( python -c "import os; print os.path.abspath('${PREDIX_SCRIPTS}')" )"
cd "${PREDIX_SCRIPTS}/${REPO_NAME}"
DIR=$( cd "$( dirname "$( find "$PWD" -maxdepth 2 -name "${SCRIPT_NAME}" )" )/.." && pwd )

source "${DIR}/spring-mvc-api/quickstart-acs-samples-functions.sh"

if [[ -n "$http_proxy" && -n "$https_proxy" ]]; then
    export MVN_SETTINGS_FILE_LOC="${DIR}/mvn_settings.xml"
    cat <<EOF > "$MVN_SETTINGS_FILE_LOC"
<?xml version="1.0" encoding="UTF-8"?>

<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">

    <proxies>
        <proxy>
            <id>http-proxy</id>
            <active>true</active>
            <protocol>http</protocol>
$(generate_maven_proxy_details "$http_proxy")
        </proxy>
        <proxy>
            <id>https-proxy</id>
            <active>true</active>
            <protocol>https</protocol>
$(generate_maven_proxy_details "$https_proxy")
        </proxy>
    </proxies>

</settings>
EOF
else
    unset MVN_SETTINGS_FILE_LOC
fi

cp "${DIR}/scripts/acs-samples"*.sh "${PREDIX_SCRIPTS_LOCATION}/bash/scripts"
cp "${DIR}/spring-mvc-api/quickstart-acs-samples-functions.sh" "${PREDIX_SCRIPTS_LOCATION}/bash/scripts"

cd "${DIR}/../.."

# NOTE: Quickstart scripts rely on $QUICKSTART_ARGS _not_ having quotes around it
source "${PREDIX_SCRIPTS}/bash/quickstart.sh" $QUICKSTART_ARGS

echo -e "\nSuccessfully completed ${APP_NAME} installation!\n"

echo -e "You can go explore the sample application code and documentation by changing directories to '${PREDIX_SCRIPTS}/${REPO_NAME}/spring-mvc-api'. If you'd like to remove the sample application and its related services from Cloud Foundry, refer to the 'Cleaning up' section at the bottom of the guide.\n"
