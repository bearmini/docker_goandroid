#!/bin/sh

CID=$(docker run -d --volumes-from my-data bearmini/goandroid-devenv)
echo $CID
