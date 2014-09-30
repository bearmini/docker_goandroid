#!/bin/bash

CID=$(docker ps --latest --quiet)
docker stop $CID
