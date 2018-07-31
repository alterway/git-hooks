#!/bin/bash

#
# PHP Lint script for all files in arguments.
#

# Get current directory
DIR_PHP_LINT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set IFS right
. ${DIR_PHP_LINT}/IFS-manager.sh

# Use dependency of block-write.
. ${DIR_PHP_LINT}/block-write.sh

NB_FILE_ERRORS=0

blocking_on_error="0"
if [[ "$1" == "-b" ]]; then
    blocking_on_error="1"
    shift
fi

ALLOWED=""
for file in $@
do
    # Only run PHP Linter on PHP files.
    EXTENSION=$(echo "$file" | egrep "\.php$")

    if [ "$EXTENSION" != "" ]; then
        ALLOWED="${ALLOWED}${file},"
    fi
done

#If empty, just return that there was no error.
if [[ -z "${ALLOWED}" ]]; then
    write_success "    PHP Lint encounters no errors."
    clean_exit 0
    return 0
fi

#Remove the last "," char
ALLOWED=${ALLOWED::-1}

random_number=${RANDOM}
USE_DOCKER=1

# -- Try to find the DOCKER service or require it if needed.
hash /etc/init.d/docker status 2>/dev/null && \
    make tools SERVICE_NAME=default ENV_NAME=.env PHP_ENV=php.env \
    CMD='run --rm php-cmd phing -f build.xml verify:smoke-list -Dlist.commit.files='${ALLOWED}' ' \
    2>/dev/null 1>/tmp/phplint-hook-${random_number} \
    || USE_DOCKER=0

if [[ "${USE_DOCKER}" -ne "1" ]]; then
    FOUND_ERRORS=0
    for file in $(echo $ALLOWED | tr "," "\n")
    do
        php -l ${file} 2>>/tmp/phplint-hook-${random_number} 1>/dev/null
    done
fi

output=$(cat /tmp/phplint-hook-${random_number}|grep "Parse error:")
if [[ -z ${output} ]]; then
    NB_FILE_ERRORS=0
else
    NB_FILE_ERRORS=$(echo ${output}|wc -l)
fi

echo ${output}
rm /tmp/phplint-hook-${random_number}

RETURN_VALUE=0

if [[ ${NB_FILE_ERRORS} -ne "0" ]]; then
    if [[ "${blocking_on_error}" == "1" ]]; then
        write_error_block 'PHP Lint found '${NB_FILE_ERRORS}' file(s) containing errors. You need fix them.'
        clean_exit 2 #Blocking error with PHP Lint.
        RETURN_VALUE=$?
    else
        write_warning_block 'PHP Lint found '${NB_FILE_ERRORS}' file(s) containing errors. You will have to fix them.'
        clean_exit 1 #Not blocking error with PHP Lint.
        RETURN_VALUE=$?
    fi
else
    write_success "    PHP Lint encounters no errors."
    clean_exit 0
    RETURN_VALUE=$?
fi

return "${RETURN_VALUE}"
