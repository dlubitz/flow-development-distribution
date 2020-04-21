#!/bin/bash -xe

#
# Create a new branch for the distribution and the development collection
#
# Expects the following environment variables:
#
# BRANCH           the branch that will be created
# BUILD_URL        used in commit message
#

set -e

if [ -z "$BRANCH" ]; then echo "\$BRANCH not set"; exit 1; fi
if [ -z "$BUILD_URL" ]; then echo "\$BUILD_URL not set"; exit 1; fi

if [ ! -e "composer.phar" ]; then
    ln -s /usr/local/bin/composer.phar composer.phar
fi

php ./composer.phar -v update

source $(dirname ${BASH_SOURCE[0]})/BuildEssentials/ReleaseHelpers.sh

# start with Base Distribution
rm -rf Distribution
git clone git@github.com:neos/flow-base-distribution.git Distribution

# branch distribution
cd Distribution && git checkout -b ${BRANCH} origin/master ; cd -
push_branch ${BRANCH} "Distribution"

# branch BuildEssentials
cd Build/BuildEssentials && git checkout -b ${BRANCH} origin/master ; cd -
push_branch ${BRANCH} "Build/BuildEssentials"

# branch development collection
cd Packages/Framework && git checkout -b ${BRANCH} origin/master ; cd -
push_branch ${BRANCH} "Packages/Framework"

# branch welcome package
cd Packages/Application/Neos.Welcome && git checkout -b ${BRANCH} origin/master ; cd -
push_branch ${BRANCH} "Packages/Application/Neos.Welcome"

$(dirname ${BASH_SOURCE[0]})/set-dependencies.sh "${BRANCH}.x-dev" ${BRANCH} "${BUILD_URL}" || exit 1

push_branch ${BRANCH} "Distribution"
push_branch ${BRANCH} "Build/BuildEssentials"
push_branch ${BRANCH} "Packages/Framework"
push_branch ${BRANCH} "Packages/Application/Neos.Welcome"

# same procedure again with the Development Distribution

rm -rf Distribution
git clone git@github.com:neos/flow-development-distribution.git Distribution

# branch distribution
cd Distribution && git checkout -b ${BRANCH} origin/master ; cd -
push_branch ${BRANCH} "Distribution"

# special case for the Development Distribution
php ./composer.phar --working-dir=Distribution require --no-update "neos/flow-development-collection:${BRANCH}.x-dev"
$(dirname ${BASH_SOURCE[0]})/set-dependencies.sh "${BRANCH}.x-dev" ${BRANCH} "${BUILD_URL}" || exit 1

push_branch ${BRANCH} "Distribution"
