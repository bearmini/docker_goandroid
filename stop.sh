#!/bin/sh

CID=$(docker ps --latest --quiet)
docker stop $CID
