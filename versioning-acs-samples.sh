#!/usr/bin/env bash

set -ex

if [[ -z "$1" ]]; then
    echo "Please provide the version to set in all POM files"
    exit 2
fi

XMLSTARLET_VERSION='1.6.1'
XMLSTARLET_DIRNAME="xmlstarlet-${XMLSTARLET_VERSION}"
XMLSTARLET_ARCHIVE_NAME="${XMLSTARLET_DIRNAME}.tar.gz"
if [[ ! -f "${XMLSTARLET_DIRNAME}/xml" ]]; then
    curl -OL "https://downloads.sourceforge.net/project/xmlstar/xmlstarlet/${XMLSTARLET_VERSION}/${XMLSTARLET_ARCHIVE_NAME}"
    tar -xvzf "${XMLSTARLET_ARCHIVE_NAME}"
    cd "$XMLSTARLET_DIRNAME"
    ./configure && make
else
    cd "$XMLSTARLET_DIRNAME"
fi

./xml ed -P -L -N x='http://maven.apache.org/POM/4.0.0' -u '/x:project/x:version' -v "$1" '../pom.xml'

\sed -i '' 's/^\( \{1,\}"version"\s*\): *".*",$/\1: "'"$1"'"/' '../version.json'