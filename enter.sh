#!/bin/sh

CID=$(docker ps --latest --quiet)
sudo docker-enter $CID /bin/bash
