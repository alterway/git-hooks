#!/bin/bash

#
# PHP Code Sniffer for all files in ${LIST} variable.
#

# Get current directory
DIR_PHP_CODE_SNIFFER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set IFS right
. ${DIR_PHP_CODE_SNIFFER}/IFS-manager.sh

# Use dependency of block-write.
. ${DIR_PHP_CODE_SNIFFER}/block-write.sh

REPO_ROOT_DIR="${DIR_PHP_CODE_SNIFFER}/../../.."

TOOLS_REPO_ROOT_DIR="${REPO_ROOT_DIR}/config/provisioning"
if [[ ! -d "${TOOLS_REPO_ROOT_DIR}" ]]; then
    TOOLS_REPO_ROOT_DIR="${REPO_ROOT_DIR}"
fi

ROOT_DIR="$(pwd)/"

FOUND_ERRORS=0

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

# Use existing phpcs ruleset, or use the default one defined in this project.
get_phpcs_ruleset() {
    PWD_GIT_REPO_TOP_LEVEL=$(git rev-parse --show-toplevel)
    # If the ruleset is defined in this repository, use it.
    if [[ -f "${PWD_GIT_REPO_TOP_LEVEL}/config/phpcs/ruleset.xml" ]]; then
        echo -e "${PWD_GIT_REPO_TOP_LEVEL}/config/phpcs/ruleset.xml"
        return 1
    fi

    # Otherwise, use the default one in the "tools" repository.
    default_ruleset_path="${1}/config/metrics/phpcs/ruleset.xml"
    if [[ -f ${default_ruleset_path} ]]; then
        echo -e "${default_ruleset_path}"
        return 1
    fi

    # Here, there is no default ruleset.xml. Analyse for errors.
    exit 255
}

###
# -- Try to find the PHP_CodeSniffer executable or require it if needed.
hash phpcs 2>/dev/null || . "${TOOLS_REPO_ROOT_DIR}/bin/provisioners/install-phpcs.sh" 2>/dev/null 1>/dev/null

###
# -- Try to find the ruleset to give configuration to PHP code sniffer.
phpcs_ruleset=$(get_phpcs_ruleset "${TOOLS_REPO_ROOT_DIR}")
if [[ $? -eq 255 ]]; then
    write_warning_block 'Impossible to find the PHP Code Sniffer ruleset. Even the clone of the Git repository containing it failed. Please check you are connected to the Internet.'
    return 12
fi

###
# - Run the PHP Codesniffer validation for each file in the ${LIST} variable.
TERMINAL_WIDTH=`tput cols`

# Clean the STDIN feed to avoid reading bad STDIN elements in PHPCS script.
while read notused; do read input; done

# Keep only a list of allowed files.
ALLOWED=()
for file in $@
do
    # Define allowed/possible file extensions that might contain debugging functions.
    EXTENSION=$(echo "$file" | egrep "\.php$")

    if [ "$EXTENSION" != "" ]; then
        ALLOWED+=(${file})
    fi

done;
ALLOWED_DOCKER=$( IFS=','; echo "${ALLOWED[*]}" )

RETURN_VALUE=0

if [ ${#ALLOWED[@]} -eq 0 ]; then
    write_success "    PHP Code Sniffer has no file to parse."
    clean_exit 0
    return "${RETURN_VALUE}"
fi

random_number=${RANDOM}

# -- Try to find the DOCKER service or require it if needed.
hash /etc/init.d/docker status 2>/dev/null && \
    make job-analyse-static tools="cs-summary" LIST_COMMIT_FILES="${ALLOWED_DOCKER}" CS_ERRORS=0 CS_WARNING=19 2>/dev/null >/tmp/phpcs-hook-${random_number} || \
    phpcs --standard=${phpcs_ruleset} --report=summary --colors --report-width=${TERMINAL_WIDTH} ${ALLOWED[@]} 2>/dev/null >/tmp/phpcs-hook-${random_number}

cat /tmp/phpcs-hook-${random_number}
FOUND_ERRORS=$(cat /tmp/phpcs-hook-${random_number} |grep 'A TOTAL OF' |grep -P '\d+ (?=ERROR)' -o)
#FOUND_WARNING=$(cat /tmp/phpcs-hook-${random_number} |grep 'A TOTAL OF' |grep -P '\d+ (?=WARNING)' -o)

rm /tmp/phpcs-hook-${random_number}

if [[ ${FOUND_ERRORS} -ne "0" ]]; then
    if [[ "${blocking_on_error}" == "1" ]]; then
        write_error_block 'PHP Code Sniffer found files containing '${FOUND_ERRORS}'errors. You need fix them.'
        clean_exit 2 #Blocking error with PHP Code sniffer.
        RETURN_VALUE=$?
    else
        write_warning_block 'PHP Code Sniffer found files containing '${FOUND_ERRORS}'errors. You will have to fix them.'
        clean_exit 1 #Not blocking error with PHP Code sniffer.
        RETURN_VALUE=$?
    fi
else
    write_success "    PHP Code Sniffer encounters no errors."
    clean_exit 0
    RETURN_VALUE=$?
fi

return "${RETURN_VALUE}"
