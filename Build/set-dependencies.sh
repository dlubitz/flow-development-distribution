#!/bin/bash

#
# Updates the dependencies in composer.json files of the dist and its
# packages.
#
# Needs the following parameters
#
# VERSION          the version that is "to be released"
# BRANCH           the branch that is worked on, used in commit message
# BUILD_URL        used in commit message
#

source $(dirname ${BASH_SOURCE[0]})/BuildEssentials/ReleaseHelpers.sh

COMPOSER_PHAR="$(dirname ${BASH_SOURCE[0]})/../composer.phar"
if [ ! -f ${COMPOSER_PHAR} ]; then
	echo >&2 "No composer.phar, expected it at ${COMPOSER_PHAR}"
	exit 1
fi

if [ -z "$1" ] ; then
	echo >&2 "No version specified (e.g. 2.1.*) as first parameter."
	exit 1
else
	if [[ $1 =~ (dev)-.+ || $1 =~ .+(@dev|.x-dev) || $1 =~ (alpha|beta|RC|rc)[0-9]+ ]] ; then
		VERSION=$1
		STABILITY_FLAG=${BASH_REMATCH[1]}
	else
		if [[ $1 =~ ([0-9]+\.[0-9]+)\.[0-9] ]] ; then
			VERSION=~${BASH_REMATCH[1]}.0
		else
			echo >&2 "Version $1 could not be parsed."
			exit 1
		fi
	fi
fi

if [ -z "$2" ] ; then
	echo >&2 "No branch specified (e.g. 2.1) as second parameter."
	exit 1
fi
BRANCH=$2

if [ -z "$3" ] ; then
	echo >&2 "No build URL specified as third parameter."
	exit 1
fi
BUILD_URL="$3"

if [ ! -d "Distribution" ]; then echo '"Distribution" folder not found. Clone the base distribution into "Distribution"'; exit 1; fi

echo "Setting distribution dependencies"

# Require exact versions of the main packages
php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "typo3/flow:${VERSION}"
php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "typo3/welcome:${VERSION}"

# Require exact versions of sub dependency packages, allowing unstable
if [[ ${STABILITY_FLAG} ]] ; then
	php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "typo3/eel:${VERSION}"
	php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "typo3/fluid:${VERSION}"
# Remove dependencies not needed if releasing a stable version
else
	# Remove requirements for development version of sub dependency packages
	php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "typo3/eel"
	php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "typo3/fluid"
fi

php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "typo3/kickstart:${VERSION}"

commit_manifest_update ${BRANCH} "${BUILD_URL}" ${VERSION} "Distribution"

echo "Setting packages dependencies"

php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/TYPO3.Flow require --no-update "typo3/eel:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/TYPO3.Flow require --no-update "typo3/fluid:~${BRANCH}.0"

for PACKAGE in TYPO3.Eel TYPO3.Fluid TYPO3.Kickstart ; do
	php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/${PACKAGE} require --no-update "typo3/flow:~${BRANCH}.0"
done

commit_manifest_update ${BRANCH} "${BUILD_URL}" ${VERSION} "Packages/Framework"
