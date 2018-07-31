#!/bin/bash
#
# Get the file list to be analysed from a command
#

# Define a function which returns 1 if file must be analyzed otherwise it returns 0
must_skip_file() {
  for folder in ${enable_folders[@]}
  do
      local reg="^$folder/*"
      if [[ $1 =~ $reg ]]; then
          return 1;
      fi
  done
  return 0;
}

# Global that will contains the list of file to be parsed.
LIST=()

# Returns the list of files that are in the scope to be checked.
get_file_list() {

    COMMAND_TO_LIST=$1

    # Declare the list of excluded patterns.
    filters_exclude=()

    # Declare the list of files that match patterns but still have to be skipped.
    skip_files=()

    # Declare the list of folders that are enabled in the wanted scope.
    enable_folders=()

    # Exclude libraries, if exist because they should not be modified.
    # Exclude scenarios and resources because they are not part of test.
    filters_exclude+=('Scenarios')
    filters_exclude+=('Resources')

    # Exclude extensions we know should not be checked.
    filters_exclude+=('\.png$')
    filters_exclude+=('\.gif$')
    filters_exclude+=('\.jpg$')
    filters_exclude+=('\.ico$')
    filters_exclude+=('\.patch$')
    filters_exclude+=('\.ad$')
    filters_exclude+=('\.htaccess$')
    filters_exclude+=('\.sh$')
    filters_exclude+=('\.ttf$')
    filters_exclude+=('\.woff$')
    filters_exclude+=('\.eot$')
    filters_exclude+=('\.svg$')
    filters_exclude+=('\.xml$')

    # Additional excludes specific to this project
    # Exclude default_bundles files.
    filters_exclude+=('\.default_bundles.inc$')
    filters_exclude+=('Makefile')
    filters_exclude+=('www\/app\/')

    # Join filters_exclude array into a single string for grep -v
    # We use egrep for the exclude since it combines better with -v.
    sep="|"
    egrep_exclude=$(printf "${sep}%s" "${filters_exclude[@]}")
    # Remove the separator from the start of the string
    egrep_exclude=${egrep_exclude:${#sep}}
    egrep_exclude="\($egrep_exclude\)"

    # Here is a default list we must filter with the list of files to skip and within the wanted scope.
    LIST=$( ${COMMAND_TO_LIST} | egrep -v "$egrep_exclude")

    skip_files+=("Makefile")

    enable_folders+=(".")

    # Set IFS right
    . ${DIR}/src/IFS-manager.sh

    # Display the list of files to be processed, for overview purposes.
    echo
    echo "File(s) to be processed/validated:"
    echo

    # Build a new list of file to parse with taking in account the skip files
    newList=()
    for file in ${LIST}
    do
        if [[ " ${skip_files[@]} " =~ " ${file} " ]]; then
            echo 'Skipped file: ' ${file}
            continue
        elif must_skip_file "${file}"; then
            echo 'Excluded file: ' ${file}
            continue
        fi
        newList+=(${file})
        # Display the path of the file because it is not ignored.
        echo '    '${file}
    done

    # Now it is done, the global LIST is set.
    LIST=${newList[*]}
}
