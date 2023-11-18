#!/bin/bash

PROJECT_ROOT=$(realpath $(dirname ${BASH_SOURCE[0]})/..)

run_container() {
    if [ -n "$LDDT_ROOT" ]; then
        return
    fi
    docker run -it --privileged -v=${PROJECT_ROOT}:/root/lddt lddt
}

run_container_bg() {
    if [ -n "$LDDT_ROOT" ]; then
        return
    fi
    docker run -td --privileged -v=${PROJECT_ROOT}:/root/lddt lddt
}

main() {
    while getopts ":fb" opt; do
        case "$opt" in
        f)
            run_container
            ;;
        b)
            run_container_bg
            ;;
        *)
            echo "error"
            exit 1
            ;;
        esac
    done
}

main $@
