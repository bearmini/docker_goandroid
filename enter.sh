#!/bin/bash

CID=$(docker ps --latest --quiet)
docker-enter $CID /bin/bash
