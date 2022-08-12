#!/bin/bash

function build() {
    clean
    docker build . -t test
}

function clean() {
    docker rm -f test
    docker rmi test
}

function test_build() {
    build
    docker run -dit --restart unless-stopped --name test test
    docker exec -it test /bin/bash
}
