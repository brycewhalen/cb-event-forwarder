#!/usr/bin/env bash
set -e

# Don't set defaults for these, if they aren't passed in we want to fail
DOCKERIZED_USER_ID=${DOCKERIZED_USER_ID}
DOCKERIZED_USER_NAME=${DOCKERIZED_USER_NAME}
DOCKERIZED_GROUP_ID=${DOCKERIZED_GROUP_ID}
DOCKERIZED_GROUP_NAME=${DOCKERIZED_GROUP_NAME}
DOCKERIZED_USER_GROUPS=${DOCKERIZED_USER_GROUPS}
DOCKERIZED_USER_HOME_DIR=${DOCKERIZED_USER_HOME_DIR}
GOPATH=${GOPATH:-/go/src}
GOBIN=${GOBIN:-/go/bin}
IFS=" "

(getent passwd ${DOCKERIZED_USER_NAME} > /dev/null) || USER_DOESNT_EXIST=1

if [[ ${USER_DOESNT_EXIST} ]]; then
    # Create dockerized user
    groupadd -f --gid ${DOCKERIZED_GROUP_ID} ${DOCKERIZED_GROUP_NAME}
    useradd --shell /bin/bash --uid ${DOCKERIZED_USER_ID} --gid ${DOCKERIZED_GROUP_NAME} --non-unique --comment "" -M ${DOCKERIZED_USER_NAME}

    # Set all groups the user is in
    for groupId in ${DOCKERIZED_USER_GROUPS}; do
        groupadd -f --gid ${groupId} "group${groupId}"
        usermod -a -G ${groupId} ${DOCKERIZED_USER_NAME}
    done

    # Create and set correct permissions on the temp home folder
    mkdir -p ${DOCKERIZED_USER_HOME_DIR}
    chown ${DOCKERIZED_USER_NAME}:${DOCKERIZED_GROUP_NAME} ${DOCKERIZED_USER_HOME_DIR}
    mkdir -p /go
    chown ${DOCKERIZED_USER_NAME}:${DOCKERIZED_GROUP_NAME} /go 
    mkdir -p $GOPATH
    chown ${DOCKERIZED_USER_NAME}:${DOCKERIZED_GROUP_NAME} $GOPATH 
    mkdir -p $GOBIN
    chown ${DOCKERIZED_USER_NAME}:${DOCKERIZED_GROUP_NAME} $GOBIN 
    mkdir -p $GOROOT 
    chown ${DOCKERIZED_USER_NAME}:${DOCKERIZED_GROUP_NAME} $GOROOT 
    gosu ${DOCKERIZED_USER_NAME} cp -r /etc/skel/. ${DOCKERIZED_USER_HOME_DIR}
fi

# Run the command
exec gosu ${DOCKERIZED_USER_NAME} "$@"
