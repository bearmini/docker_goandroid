#!/bin/sh

docker_enter() {
    boot2docker ssh '[ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /var/lib/boot2docker/:/target jpetazzo/nsenter'
    boot2docker ssh -t sudo /var/lib/boot2docker/docker-enter "$@"
}

PLATFORM=`uname`
case $PLATFORM in
    Linux)
        \command -v docker-enter >/dev/null 2>&1 || { echo >&2 "'docker-enter' is required.  Aborting."; exit 1; }
        ENTER="sudo docker-enter"
        ;;
    *)
        ENTER=docker_enter
        ;;
esac

CID=$(docker ps --latest --quiet)
$ENTER $CID /bin/bash
