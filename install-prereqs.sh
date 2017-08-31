#!/usr/bin/env bash

{ set -e; } 2> /dev/null

# Temporarily disable verification of all SSL peers and hosts
APT_SSL_VERIFY_FILE='/etc/apt/apt.conf.d/ssl-verify'
sudo tee "$APT_SSL_VERIFY_FILE" > /dev/null <<'EOF'
Acquire::https {
    Verify-Peer "false";
    Verify-Host "false";
}
EOF

# Install Linuxbrew dependencies
if [[ "$(apt list --installed build-essential curl file git python-setuptools ruby jq 2> /dev/null | awk '/^Listing/{l=1;next}l' | grep '\[installed\]$' | wc -l)" -ge 7 ]]; then
    echo 'Linuxbrew dependencies are already installed!'
else
    { set -x; } 2> /dev/null
    sudo -E apt-get -y update
    sudo -E apt-get -y install build-essential curl file git python-setuptools ruby jq
    { set +x; } 2> /dev/null
fi

# Install Linuxbrew
if [[ -f '/home/linuxbrew/.linuxbrew/bin/brew' ]]; then
    echo 'Linuxbrew is already installed!'
else
    { set -x; } 2> /dev/null
    echo | ruby -e "$(curl -fsSL 'https://raw.githubusercontent.com/Linuxbrew/install/master/install')"
    sudo chown -R "$(whoami)" /home/linuxbrew
    sudo chgrp -R "$(whoami)" /home/linuxbrew
    sudo chmod -R 0755 /home/linuxbrew
    echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    { set +x; } 2> /dev/null
fi

# Install Cloud Foundry CLI
if [[ "$(apt list --installed cf-cli 2> /dev/null | awk '/^Listing/{l=1;next}l' | grep '\[installed\]$' | wc -l)" -ge 1 ]]; then
    echo 'Cloud Foundry CLI is already installed!'
else
    { set -x; } 2> /dev/null
    wget -e http_proxy="$http_proxy" -e https_proxy="$https_proxy" --no-check-certificate -q -O - 'https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key' | sudo apt-key add -
    echo 'deb http://packages.cloudfoundry.org/debian stable main' | sudo tee '/etc/apt/sources.list.d/cloudfoundry-cli.list'
    sudo -E apt-get -y update
    sudo -E apt-get -y install cf-cli
    { set +x; } 2> /dev/null
fi

# Install the "cf-predix" plugin
if [[ "$(cf plugins | grep -q 'Predix.*1\.0\.0.*predix'; echo "$?")" -eq 0 ]]; then
    echo 'The "cf-predix" plugin is already installed!'
else
    sudo tee "/usr/local/share/ca-certificates/GE_External_Root_CA_2_1.crt" > /dev/null <<'EOF'
-----BEGIN CERTIFICATE-----
MIIDozCCAougAwIBAgIQeO8XlqAMLhxvtCap35yktzANBgkqhkiG9w0BAQsFADBS
MQswCQYDVQQGEwJVUzEhMB8GA1UEChMYR2VuZXJhbCBFbGVjdHJpYyBDb21wYW55
MSAwHgYDVQQDExdHRSBFeHRlcm5hbCBSb290IENBIDIuMTAeFw0xNTAzMDUwMDAw
MDBaFw0zNTAzMDQyMzU5NTlaMFIxCzAJBgNVBAYTAlVTMSEwHwYDVQQKExhHZW5l
cmFsIEVsZWN0cmljIENvbXBhbnkxIDAeBgNVBAMTF0dFIEV4dGVybmFsIFJvb3Qg
Q0EgMi4xMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzCzT4wNRZtr2
XTzoTMjppjulZfG35/nOt44q2zg47sxwgZ8o4qjcrwzIhsntoFrRQssjXSF5qXdC
zsm1G7f04qEBimuOH/X+CidWX+sudCS8VyRjXi9cyvUW4/mYKCLXv5M6HhEoIHCD
Xdo6yUr5mSrf18qRR3yUFz0HYXopa2Ls3Q6lBvEUO2Xw04vqVvmg1h7S5jYuZovC
oIbd2+4QGdoSZPgtSNpCxSR+NwtPpzYZpmqiUuDGfVpO3HU42APB0c60D91cJho6
tZpXYHDsR/RxYGm02K/iMGefD5F4YMrtoKoHbskty6+u5FUOrUgGATJJGtxleg5X
KotQYu8P1wIDAQABo3UwczASBgNVHRMBAf8ECDAGAQH/AgECMA4GA1UdDwEB/wQE
AwIBBjAuBgNVHREEJzAlpCMwITEfMB0GA1UEAxMWR0UtUm9vdC1DT00tUlNBLTIw
NDgtMTAdBgNVHQ4EFgQU3N2mUCJBCLYgtpZyxBeBMJwNZuowDQYJKoZIhvcNAQEL
BQADggEBACF4Zsf2Nm0FpVNeADUH+sl8mFgwL7dfL7+6n7hOgH1ZXcv6pDkoNtVE
0J/ZPdHJW6ntedKEZuizG5BCclUH3IyYK4/4GxNpFXugmWnKGy2feYwVae7Puyd7
/iKOFEGCYx4C6E2kq3aFjJqiq1vbgSS/B0agt1D3rH3i/+dXVxx8ZjhyZMuN+cgS
pZL4gnhnSXFAGissxJhKsNkYgvKdOETRNn5lEgfgVyP2iOVqEguHk2Gu0gHSouLu
5ad/qyN+Zgbjx8vEWlywmhXb78Gaf/AwSGAwQPtmQ0310a4DulGxo/kcuS78vFH1
mwJmHm9AIFoqBi8XpuhGmQ0nvymurEk=
-----END CERTIFICATE-----
EOF
    sudo update-ca-certificates
    { set -x; } 2> /dev/null
    cf install-plugin -f 'https://github.com/PredixDev/cf-predix/releases/download/1.0.0/predix_linux64'
    { set +x; } 2> /dev/null
fi

# Install Predix CLI
{ set +e; } 2> /dev/null
PX_LOCATION=$(which px)
{ set -e; } 2> /dev/null
if [[ -n "$PX_LOCATION" ]]; then
    echo 'Predix CLI is already installed!'
else
    { set -x; } 2> /dev/null
    wget -e http_proxy="$http_proxy" -e https_proxy="$https_proxy" --no-check-certificate 'https://github.com/PredixDev/predix-cli/releases/download/v0.5.4/predix-cli.tar.gz'
    mkdir predix-cli
    tar -xvzf 'predix-cli.tar.gz' -C predix-cli
    cd predix-cli
    sudo ./install
    { set +x; } 2> /dev/null
fi

# Install Java
if [[ "$(apt list --installed oracle-java8-installer 2> /dev/null | awk '/^Listing/{l=1;next}l' | grep '\[installed\]$' | wc -l)" -ge 1 ]]; then
    echo 'Oracle Java is already installed!'
else
    { set -x; } 2> /dev/null
    cat <<'EOF' | sudo apt-key add -
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: SKS 1.1.6
Comment: Hostname: keyserver.ubuntu.com

mI0ES9/P3AEEAPbI+9BwCbJucuC78iUeOPKl/HjAXGV49FGat0PcwfDd69MVp6zUtIMbLgkU
OxIlhiEkDmlYkwWVS8qy276hNg9YKZP37ut5+GPObuS6ZWLpwwNus5PhLvqeGawVJ/obu7d7
gM8mBWTgvk0ErnZDaqaU2OZtHataxbdeW8qH/9FJABEBAAG0DUxhdW5jaHBhZCBWTEOImwQQ
AQIABgUCVsN4HQAKCRAEC6TrO3+B2tJkA/jM3b7OysTwptY7P75sOnIu+nXLPlzvja7qH7Wn
A23itdSker6JmyJrlQeQZu7b9x2nFeskNYlnhCp9mUGu/kbAKOx246pBtlaipkZdGmL4qXBi
+bi6+5Rw2AGgKndhXdEjMxx6aDPq3dftFXS68HyBM3HFSJlf7SmMeJCkhNRwiLYEEwECACAF
Akvfz9wCGwMGCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRDCUYJI7qFIhucGBADQnY4V1xKT
1Gz+3ERly+nBb61BSqRx6KUgvTSEPasSVZVCtjY5MwghYU8T0h1PCx2qSir4nt3vpZL1luW2
xTdyLkFCrbbIAZEHtmjXRgQu3VUcSkgHMdn46j/7N9qtZUcXQ0TOsZUJRANY/eHsBvUg1cBm
3RnCeN4C8QZrir1CeA==
=CziK
-----END PGP PUBLIC KEY BLOCK-----
EOF
    UBUNTU_CODENAME="$(lsb_release -sc)"
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu ${UBUNTU_CODENAME} main" | sudo tee "/etc/apt/sources.list.d/webupd8team-ubuntu-java-${UBUNTU_CODENAME}.list"
    sudo -E apt-get -y update
    echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections
    sudo -E apt-get -y install oracle-java8-installer
    { set +x; } 2> /dev/null
fi

# Install Maven
if [[ "$(apt list --installed maven 2> /dev/null | awk '/^Listing/{l=1;next}l' | grep '\[installed\]$' | wc -l)" -ge 1 ]]; then
    echo 'Maven is already installed!'
else
    { set -x; } 2> /dev/null
    sudo -E apt-get -y update
    sudo -E apt-get -y install maven
    { set +x; } 2> /dev/null
fi

# Re-enable verification of all SSL peers and hosts
sudo rm -f "$APT_SSL_VERIFY_FILE"
