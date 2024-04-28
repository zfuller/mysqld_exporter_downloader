#!/bin/bash

# This script downloads and installs the specified version (or latest if not specified) of mysqld_exporter
# from the official Prometheus GitHub repository: https://github.com/prometheus/mysqld_exporter.

RELEASE_URL="https://api.github.com/repos/prometheus/mysqld_exporter/releases"

while getopts ":b:v:fdh" opt; do
	case $opt in
		b) DEST_BIN="$OPTARG"
		;;
		v) if [[ $OPTARG != v* ]]; then
				VERSION="v$OPTARG"
			else
				VERSION="$OPTARG"
			fi
		;;
		f) FORCE="true"
		;;
		d) set -x
		;;
		h) echo "Usage: $0 [-b /path/to/binary] [-v version] [-f] [-d]"
			echo "  -b  Specify the destination path for the mysqld_exporter binary (default: /usr/local/bin/mysqld_exporter)"
			echo "  -v  Specify the version of mysqld_exporter to download (default: latest)"
			echo "  -f  Force update even if the current version is the same as the specified version"
			echo "  -d  Enable debug mode"
			echo "  -h  Display this help message"
			exit 0
		;;
		\?) echo "Invalid option -$OPTARG" >&2
			exit 1
		;;
	esac
done

DEST_BIN=${DEST_BIN:-/usr/local/bin/mysqld_exporter}

if [ -z "$VERSION" ]; then
	VERSION=$(curl -s "$RELEASE_URL/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
else
	if ! curl -s "$RELEASE_URL/tags/$VERSION" | grep -q '"tag_name"'; then
		echo "Version $VERSION not found."
		exit 1
	fi
fi

if [ -f "$DEST_BIN" ]; then
	CURRENT_VERSION=$($DEST_BIN --version 2>&1 | awk 'NR==1{print $3}')
	echo "Current mysqld_exporter version: $CURRENT_VERSION"
else
	CURRENT_VERSION=""
fi

if [ "$CURRENT_VERSION" != "${VERSION#v}" ] || [ "$FORCE" == "true" ]; then
	echo "Installing new version: $VERSION"
	DOWNLOAD_URL="https://github.com/prometheus/mysqld_exporter/releases/download/$VERSION/mysqld_exporter-${VERSION#v}.linux-amd64.tar.gz"
	curl -s -L $DOWNLOAD_URL -o mysqld_exporter_$VERSION.tar.gz

	if [ -f mysqld_exporter_$VERSION.tar.gz ]; then
		tar -xzf mysqld_exporter_$VERSION.tar.gz
	else
		echo "Download failed: mysqld_exporter_$VERSION.tar.gz does not exist."
		exit 1
	fi

	if [ -z "$VERSION" ]; then
		echo "adding latest mysqld_exporter to $DEST_BIN"
	else
		echo "adding given version mysqld_exporter ($VERSION) to $DEST_BIN"
	fi
	mv mysqld_exporter-${VERSION#v}.linux-amd64/mysqld_exporter $DEST_BIN
	rm mysqld_exporter_$VERSION.tar.gz
	rm -r mysqld_exporter-${VERSION#v}.linux-amd64

	echo "mysqld_exporter has been updated to version $VERSION"
else
	echo "mysqld_exporter is already at version $VERSION"
fi

exit 0
