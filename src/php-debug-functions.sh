#!/bin/bash

#
# Check for debugging functions.
#

# Get current directory
DIR_PHP_DEBUG_FUNCTION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set IFS right
. ${DIR_PHP_DEBUG_FUNCTION}/IFS-manager.sh

# Use dependency of block-write.
. ${DIR_PHP_DEBUG_FUNCTION}/block-write.sh

# Build the list of PHP blacklisted functions
checks=()
checks+=("\<dump(")
checks+=("\<var_dump(")
checks+=("\<print_r(")
checks+=("\<die(")

# Blacklist Drupal's built-in debugging function
checks+=("\<debug(")

# Blacklist Devel's debugging functions
checks+=("\<dpm(")
checks+=("\<krumo(")
checks+=("\<dpr(")
checks+=("\<dsm(")
checks+=("\<dd(")
checks+=("\<ddebug_backtrace(")
checks+=("\<dpq(")
checks+=("\<dprint_r(")
checks+=("\<drupal_debug(")
checks+=("\<dsm(")
checks+=("\<dvm(")
checks+=("\<dvr(")
checks+=("\<kpr(")
checks+=("\<kprint_r(")
checks+=("\<kdevel_print_object(")
checks+=("\<kdevel_print_object(")

# Blacklist code conflicts resulting from Git merge.
checks+=("<<<<<<<")
checks+=(">>>>>>>")

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
    EXTENSION=$(echo "$file" | egrep "\.install$|\.test$|\.inc$|\.module$|\.php$")

    if [ "$EXTENSION" != "" ]; then

        for debug_function in ${checks[*]}
        do
            # Find the blacklisted functions in the current file.
            ERRORS=$(grep -n "$debug_function" ${ROOT_DIR}${file} >&1)
            ERROR_LINE=`cut -d':' -f 1 <<< "${ERRORS}"`
            ERROR_TEXT=`cut -d':' -f 2- <<< "${ERRORS}"`
            ERROR_TEXT="${ERROR_TEXT#"${ERROR_TEXT%%[![:space:]]*}"}" # remove leading whitespace characters
            ERROR_TEXT="${ERROR_TEXT%"${ERROR_TEXT##*[![:space:]]}"}" # remove trailing whitespace characters

            if [[ ! -z "$ERRORS" ]]; then
                ERRORS_BUFFER+=("${ERROR_TEXT} found in file: ${file}:${ERROR_LINE}")
            fi
        done
    fi
done

RETURN_VALUE=0

if [[ ! -z "$ERRORS_BUFFER" ]]; then
    if [[ "${blocking_on_error}" == "1" ]]; then
        write_error_block ${ERRORS_BUFFER[*]}
        clean_exit 2 #Blocking error with PHP Debug functions.
        RETURN_VALUE=$?
    else
        write_warning_block ${ERRORS_BUFFER[*]}
        clean_exit 1 #Not blocking error with PHP Debug functions.
        RETURN_VALUE=$?
    fi
else
    write_success "    PHP Debugging functions encounters no errors."
    clean_exit 0
    RETURN_VALUE=$?
fi

return "${RETURN_VALUE}"
