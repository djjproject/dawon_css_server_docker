#!/bin/bash

CONTAINER_NAME=test
IMAGE_NAME=djjproject/dawon_css_server
IMAGE_TAG=release-e1d011ae

function build() {
    clean
    docker build . -t $IMAGE_NAME:$IMAGE_TAG
}

function clean() {
    docker rm -f $IMAGE_NAME:$IMAGE_TAG
    docker rmi $IMAGE_NAME:$IMAGE_TAG
    docker rmi $IMAGE_NAME:latest
}

function test_build() {
    build
    docker run -dit --restart unless-stopped --network host -v /opt/powermanager:/app/data --name $CONTAINER_NAME $IMAGE_NAME:$IMAGE_TAG
    docker exec -it $CONTAINER_NAME /bin/bash
}

function push_image() {
    build
    docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
    docker push $IMAGE_NAME:$IMAGE_TAG
    docker push $IMAGE_NAME:latest
    clean
}
