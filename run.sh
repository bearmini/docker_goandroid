#!/bin/bash

CID=$(docker run -d bearmini/goandroid-devenv)
echo $CID
