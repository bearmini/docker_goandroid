#!/bin/sh

CID=$(docker run -d --privileged -p 5037:5037 -v /dev/bus/usb:/dev/bus/usb --volumes-from my-data bearmini/mandala-docker)
echo $CID
