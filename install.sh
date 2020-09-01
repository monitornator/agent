#!/bin/bash

export LC_ALL=C

currentlyNotSupported() {
    echo "$OS $VER is currently not supported, please drop us a line (hi@monitornator.io) if you need it!"
    exit
}

# TODO Check OS
detectOs () {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    echo "Detected $OS $VER"

    case $OS in
        # Darwin)
        #     if [ "$VER" = "17.4.0" ]; then
        #         setupMacOs
        #     else
        #         currentlyNotSupported
        #     fi
        #     ;;
        'Debian GNU/Linux')
            if [ $VER == '9' ]; then
                setupUbuntu
            elif [ $VER == '10' ]; then
                setupUbuntu
            else
            else
                currentlyNotSupported
            fi
            ;;
        Ubuntu)
            if [ $VER == '16.04' ]; then
                setupUbuntu
            elif [ $VER == '18.04' ]; then
                setupUbuntu
            elif [ $VER == '18.10' ]; then
                setupUbuntu
            elif [ $VER == '20.04' ]; then
                setupUbuntu
            elif [ $VER == '14.04' ]; then
                setupUbuntu
            else
                currentlyNotSupported
            fi
            ;;
        'Raspbian GNU/Linux')
            if [ $VER == '10' ]; then
                setupUbuntu
            else
                currentlyNotSupported
            fi
            ;;
        *)
            currentlyNotSupported
    esac
}

setupMacOs () {
    # TODO Implement
    echo 'Setting up Monitornator on macOs'
    pyv="$(python3 -V 2>&1)"
    echo "$pyv"
    # brew install python3

    setupPython
}

setupUbuntu () {
    getConfirmation

    AGENT_DIR="/usr/local/bin/monitornator"
    AGENT_CONFIG_DIR="/etc/monitornator"
    echo "Setting up Monitornator on Ubuntu"
    sudo apt-get install software-properties-common -y
    sudo add-apt-repository universe
    sudo apt-get install build-essential python3 python3-dev python3-setuptools python3-pip supervisor -y
    setupPython
    sudo mkdir -p $AGENT_DIR
    (cd $AGENT_DIR && sudo curl -sSL -O https://agent.monitornator.io/monitornator.py && sudo chmod u+x monitornator.py)
    sudo mkdir -p $AGENT_CONFIG_DIR

    if [ -z ${HOST+x} ]; then
      echo "[monitornator]
server_id = $SERVER_ID
token = $TOKEN" | sudo tee "$AGENT_CONFIG_DIR/monitornator.config"
    else
      echo "[monitornator]
server_id = $SERVER_ID
token = $TOKEN
host = $HOST" | sudo tee "$AGENT_CONFIG_DIR/monitornator.config"
    fi

    echo "[program:monitornator]
autorestart=true
command=python3 $AGENT_DIR/monitornator.py
user=$USER
stderr_logfile=$AGENT_DIR/error.log
stderr_logfile_maxbytes=1MB" | sudo tee "/etc/supervisor/conf.d/monitornator.conf"
    sudo supervisorctl reread
    sudo supervisorctl update
}

setupPython() {
    echo 'Setting up python dependencies'
    pip3 install wheel
    pip3 install psutil
    echo 'Done'
}

getConfirmation() {
  echo ""
  echo "This script will install Monitornator agent on your system including the following dependencies (if not yet present):"
  echo "- software-properties-common"
  echo "- build-essential"
  echo "- python3"
  echo "- python3-dev"
  echo "- python3-pip"
  echo "- python3-setuptools"
  echo "- supervisor"
  echo ""
  read -p "Do you wish to continue? (y/N): " choice
  case "$choice" in 
    y|Y ) echo "yes";;
    n|N ) exit 1;;
    * ) exit 1;;
  esac
}

while [ $# -gt 0 ]; do
  echo $1
  case "$1" in
    --server-id=*)
      SERVER_ID="${1#*=}"
      ;;
    --token=*)
      TOKEN="${1#*=}"
      ;;
    --host=*)
      HOST="${1#*=}"
      ;;
    *)
      printf "[Error] Invalid argument: $1\n"
      exit 1
  esac
  shift
done

echo "Running install script for"
echo "$SERVER_ID"
echo "$TOKEN"

if [ -z ${SERVER_ID+x} ]; then
  echo "--server-id is a required argument."
  exit 1;
fi

if [ -z ${TOKEN+x} ]; then
  echo "--token is a required argument."
  exit 1;
fi

detectOs
