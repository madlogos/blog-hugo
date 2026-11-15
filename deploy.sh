#!/bin/bash

set -e

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# commit this change
git add -A
git diff --cached --quiet || git commit -m "changes on `date`"
git push origin master

# Build the project.
hugo -t even # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd public
# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git diff --cached --quiet || git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..
