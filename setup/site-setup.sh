# This script automates/acts as a reference for cloning a Craft site repository into the workspace.
# It should be run from the vagrant environment directory of the HOST with the following options:
#
# site-setup.sh /path/to/repository

# Ensure the remote is valid before even trying.
git ls-remote $1 > /dev/null
if [[ $? -ne 0 ]]; then
    exit 1
fi
# Start in the root site/workspace folder.
cd workspace
# Create our blank repository with no remote.
git init
# Add the provided repository as our remote to pull from.
git remote add origin $1
# Get the repository information from the remote.
git fetch
# Checkout the master branch from the remote, forcing it over the existing files.
git checkout -t origin/master -f