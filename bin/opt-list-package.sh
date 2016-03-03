#! /bin/bash
# List files in a package.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-list-package <package-name>"
}

if [ $# -eq 1 ]
then
    case "$1" in
	--help)
	    usage
	    exit 0
	    ;;
	--version)
	    opt_print_version
	    exit 0
	    ;;
    esac
fi

if [ $# -ne 1 ]
then
    usage >&2
    exit 1
fi

package="$1"
contents_file="${package}.contents"

cd $OPT_DB_DIR

if [ ! -f "$contents_file" ]
then
    echo "Not an installed package: $package" >&2
    exit 1
fi

cat "$contents_file"
