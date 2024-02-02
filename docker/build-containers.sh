#!/bin/bash


docker buildx build -f Dockerfile -t hacksaw:0.1 .

pushd imager
docker buildx build -f Dockerfile -t hacksaw-imager:0.1 .
popd
