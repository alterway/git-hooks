#!/bin/bash

# If .git is not an existing folder, run the `git init` command to create it.
if [[ ! -d "./.git" ]]; then
    git init
fi

# Remove the current hooks as they will be replaced after
rm -rf .git/hooks

# As this script is in the phing repository, use the file path of the script to determine the path of the hooks
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

hooksDir="${DIR}/.."
targetDir=".git"

# Now, copy the hooks
cp -R "${hooksDir}" "${targetDir}"/hooks
chmod -R +x "${targetDir}"/hooks

# Remove the extensions of the hooks because they need to have no extension
cd "${targetDir}"/hooks
rename 's/\.sh//' *.sh 1>/dev/null 2>/dev/null
cd - 1>/dev/null 2>/dev/null

# Your repository is clean now.
exit 0
