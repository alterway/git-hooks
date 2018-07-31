#!/bin/bash

if [[ -z ${LIST} ]]; then
    echo "No file in the list to check."
    echo ""
    exit 0
fi

arg_block=""
if [[ "$1" == "-b" ]]; then
    arg_block="-b"
fi

RETURN_CODE=0

echo
echo "************************************************************************"
echo "*                                                                      *"
echo "*   ===================== GIT HOOK FOR SYMFONY =====================   *"
echo "*                                                                      *"
echo "*   Check the following filters:                                       *"
echo "*     I. Syntax checking using PHP Linter                              *"
echo "*    II. Coding standards checking using PHP Code Sniffer              *"
echo "*   III. Blacklisted functions checking/validation.                    *"
echo "*    IV. Alert usages of forbidden statements in PHP.                  *"
#echo "*     V. Bad encoding detector.                                        *"
echo "*                                                                      *"
echo "************************************************************************"

echo
echo -e "\e[1;34m  I. Running PHP Lint.\e[0;49;39m"
echo
. ${DIR}/src/php-linter.sh ${arg_block} ${LIST}
((RETURN_CODE += $?))

echo
echo -e "\e[1;34m  II. Running the PHP Code Sniffer.\e[0;49;39m"
echo
. ${DIR}/src/php-code-sniffer.sh ${arg_block} ${LIST}
((RETURN_CODE += $?))

echo
echo -e "\e[1;34m  III. Running the checker/validator for blacklisted functions.\e[0;49;39m"
echo
. ${DIR}/src/php-debug-functions.sh ${arg_block} ${LIST}
((RETURN_CODE += $?))

echo
echo -e "\e[1;34m  IV. Alerting the usages of forbidden statements in PHP.\e[0;49;39m"
echo
. ${DIR}/src/php-forbidden-functions.sh ${arg_block} ${LIST}
((RETURN_CODE += $?))

#echo
#echo -e "\e[1;34m  V. Running the file encoding checker.\e[0;49;39m"
#echo
#. ${DIR}/bin/php-encoding-checking.sh ${arg_block} ${LIST}
#((RETURN_CODE += $?))

if [[ "${RETURN_CODE}" == "0" ]]; then
    write_success_block "SUCCESS!! You passed all the tests."
    clean_exit
elif [[ ${arg_block} != "-b" ]]; then
    write_warning_block "WARNING!! You encountered some errors but they are not blocking your command. Be aware that you should fix them as soon as possible."
    clean_exit
else
    write_error_block "ERROR!! You encountered some errors blocking your command. You must fix them."
    clean_exit 2
fi
