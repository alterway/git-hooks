#!/bin/bash

#
# Check for forbidden functions or statements.
#

# Get current directory
DIR_PHP_FORBIDDEN_FUNCTION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set IFS right
. ${DIR_PHP_FORBIDDEN_FUNCTION}/IFS-manager.sh

# Use dependency of block-write.
. ${DIR_PHP_FORBIDDEN_FUNCTION}/block-write.sh

# Build the list of PHP blacklisted functions
regexpForbid=()

PHP_FORBIDDEN_FUNCTION_OLD_IFS=$IFS
IFS=$'\n'
for line in $(cat ${DIR_PHP_FORBIDDEN_FUNCTION}/php.db)
do
    if [ "${line:0:1}" == "#" ]; then
        continue
    fi
    regexpForbid+=("${line}")
done
IFS=${PHP_FORBIDDEN_FUNCTION_OLD_IFS}

ROOT_DIR="$(pwd)/"
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
    # Define allowed/possible file extensions that might contain debugging functions.
    EXTENSION=$(echo "$file" | egrep "\.php$")

    if [ "$EXTENSION" != "" ]; then

        for forbidden_function in ${regexpForbid[*]}
        do
            # Find the blacklisted functions in the current file.
            ERRORS=$(egrep -n "$forbidden_function" ${ROOT_DIR}${file} >&1)
            ERRORS_LINE=`cut -d':' -f 1 <<< "${ERRORS}"`
            if [[ ! -z "$ERRORS" ]]; then
                for ERROR_LINE in ${ERRORS_LINE}; do
                    ERRORS_BUFFER+=("Forbidden statement ${forbidden_function} found in file: ${file}:${ERROR_LINE}")
                done
            fi
        done
    fi
done

RETURN_VALUE=0

if [[ ! -z "$ERRORS_BUFFER" ]]; then
    if [[ "${blocking_on_error}" == "1" ]]; then
        write_error_block ${ERRORS_BUFFER[*]}
        clean_exit 2 #Blocking error with PHP Forbidden functions.
        RETURN_VALUE=$?
    else
        write_warning_block ${ERRORS_BUFFER[*]}
        clean_exit 1 #Not blocking error with PHP Forbidden functions.
        RETURN_VALUE=$?
    fi
else
    write_success "    PHP Forbidden statements encounters no errors."
    clean_exit 0
    RETURN_VALUE=$?
fi

return "${RETURN_VALUE}"
