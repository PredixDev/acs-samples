#!/usr/bin/env bash

QUICKSTART_ROOT_DIR="$quickstartRootDir"
QUICKSTART_LOG_DIR="${QUICKSTART_ROOT_DIR}/log"
QUICKSTART_SUMMARY_TEXTFILE="${QUICKSTART_LOG_DIR}/quickstart-summary.txt"

function append_to_quickstart_summary() {
    { SAVED_OPTIONS=$(set +o); } > /dev/null 2>&1
    { set +x; } 2> /dev/null
    echo -e "\n${1}\n"
    if [[ -d "$QUICKSTART_ROOT_DIR" ]]; then
        echo -e "    - $1" >> "$QUICKSTART_SUMMARY_TEXTFILE"
    fi
    { eval "$SAVED_OPTIONS"; } > /dev/null 2>&1
}

PROXY_PREFIX_REGEX='^http[s]??://(.*?:)?(.*?@)?'

function get_proxy_host() {
    echo "$(echo "${1%%:[0-9]*}" | python -c "import re, sys; print ''.join(re.sub(r'${PROXY_PREFIX_REGEX}', r'', line.strip()) for line in sys.stdin)")"
}

function get_proxy_port() {
    echo "$(echo "${1##*:}" | python -c "import re, sys; print ''.join(re.sub(r'/??$', r'', line.strip()) for line in sys.stdin)")"
}

function get_proxy_username() {
    echo "$(echo "${1%%:[0-9]*}" | python -c "import re, sys; print ''.join(re.sub(r'${PROXY_PREFIX_REGEX}.*$', lambda m: m.group(1) or '', line.strip()) for line in sys.stdin)" | cut -d ':' -f 1)"
}

function get_proxy_password() {
    echo "$(echo "${1%%:[0-9]*}" | python -c "import re, sys; print ''.join(re.sub(r'${PROXY_PREFIX_REGEX}.*$', lambda m: m.group(2) or '', line.strip()) for line in sys.stdin)" | cut -d '@' -f 1)"
}