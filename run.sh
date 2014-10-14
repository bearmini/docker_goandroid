#!/bin/sh

CID=$(docker run -d --privileged -v /dev/bus/usb:/dev/bus/usb --volumes-from my-data bearmini/goandroid-devenv)
echo $CID
