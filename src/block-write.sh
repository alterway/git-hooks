#!/bin/bash

write_block() {
    #Keep the status and shift to keep only all messages as arguments.
    status="$1"
    shift

    ALL_MSG_LINES=()
    LONGEST_LINE_LENGTH=0
    MAX_LINE_LENGTH=$(( `tput cols` - 16 ))
    for msg in $*
    do
        msg="${msg#"${msg%%[![:space:]]*}"}" # remove leading whitespace characters
        msg="${msg%"${msg##*[![:space:]]}"}" # remove trailing whitespace characters

        #If, after trimming, the message is empty, do not add it in the list of messages to display, so continue.
        if [[ -z ${msg} ]]; then
            continue
        fi

        ALL_MSG_LINES+=(`fold -sw ${MAX_LINE_LENGTH} <<< "${msg}"`)
        CURRENT_LINE_LENGTH=${#msg}
        if [[ ${CURRENT_LINE_LENGTH} -gt ${MAX_LINE_LENGTH} ]]; then
            CURRENT_LINE_LENGTH=${MAX_LINE_LENGTH}
        fi
        if [[ ${LONGEST_LINE_LENGTH} -lt ${CURRENT_LINE_LENGTH} ]]; then
            LONGEST_LINE_LENGTH=${CURRENT_LINE_LENGTH}
        fi
    done

    # If no more message to display, get out.
    if [ ${#ALL_MSG_LINES[@]} -eq 0 ]; then
        return 0
    fi

    case "${status}" in
        "error") colorCode="\e[41;37m"
        ;;
        "warning") colorCode="\e[43;30m"
        ;;
        "success") colorCode="\e[42;30m"
        ;;
        *) colorCode="\e[49;39m"
        ;;
    esac

    block_length=$(( ${LONGEST_LINE_LENGTH} + 8 ))
    border=`printf %${block_length}s`

    echo -ne "\e[49;39m\n"
    echo -ne "\e[49;39m    ${colorCode}${border}\e[49;39m    \n"
    for msg in ${ALL_MSG_LINES[*]}
    do
        trailing_spaces_number=$(( 4 + ${LONGEST_LINE_LENGTH} - ${#msg} ))
        echo -ne "\e[49;39m    ${colorCode}    ${msg}"`printf %${trailing_spaces_number}s`"\e[49;39m    \n"
    done
    echo -ne "\e[49;39m    ${colorCode}${border}\e[49;39m    \n"
    echo -ne "\e[49;39m\n"
}

write() {
    #Keep the status and shift to keep only all messages as arguments.
    status="$1"
    shift

    case "${status}" in
        "error") colorCode="\e[31m"
        ;;
        "warning") colorCode="\e[33m"
        ;;
        "success") colorCode="\e[32m"
        ;;
        "info") colorCode="\e[34m"
        ;;
        *) colorCode="\e[39m"
        ;;
    esac

    for msg in $*
    do
        echo -ne "${colorCode}${msg}\e[39m\n"
    done
}

write_error_block() {
    write_block "error" $@
}
write_warning_block() {
    write_block "warning" $@
}
write_success_block() {
    write_block "success" $@
}

write_error() {
    write "error" $@
}
write_warning() {
    write "warning" $@
}
write_success() {
    write "success" $@
}
write_info() {
    write "info" $@
}
