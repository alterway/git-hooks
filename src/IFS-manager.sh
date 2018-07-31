#!/bin/bash

# IFS is a bash internal defines the separator for looping over a string.
IFSBACK=${IFS}
IFS=$'\n'

# Define a function to exit or return which can reset $IFS.
clean_exit() {
    IFS=$IFSBACK
    returnValue=${1:-0}

    if [[ -z "${BASH_SOURCE[2]}" ]]; then
        exit ${returnValue}
    else
        return ${returnValue}
    fi
}
