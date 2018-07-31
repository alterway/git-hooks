#!/bin/bash

#
# Check for debugging functions.
#
# Get current directory
DIR_ENCODING_CHECKING="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set IFS right
. ${DIR_ENCODING_CHECKING}/IFS-manager.sh

# Use dependency of block-write.
. ${DIR_ENCODING_CHECKING}/block-write.sh

ERRORS_BUFFER=()

blocking_on_error="0"
if [[ "$1" == "-b" ]]; then
    blocking_on_error="1"
    shift
fi

################################################################################
#                                                                              #
#                                   M A I N                                    #
#                                                                              #
################################################################################

for file in $@
do
    ENCODING=$(file -ib ${file})
    if [ "$ENCODING" != "text/plain; charset=utf-8" ]; then
        ERRORS_BUFFER+=("This file is not encoded in UTF-8: $file")
    fi
done

RETURN_VALUE=0

if [[ ! -z "$ERRORS_BUFFER" ]]; then
    if [[ "${blocking_on_error}" == "1" ]]; then
        write_error_block ${ERRORS_BUFFER[*]}
        clean_exit 2 #Blocking error with encoding checker.
        RETURN_VALUE=$?
    else
        write_warning_block ${ERRORS_BUFFER[*]}
        clean_exit 1 #Not blocking error with encoding checker.
        RETURN_VALUE=$?
    fi
else
    write_success "    Encoding for each file is good."
    clean_exit 0
    RETURN_VALUE=$?
fi

return "${RETURN_VALUE}"
