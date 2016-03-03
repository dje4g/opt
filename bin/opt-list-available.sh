#! /bin/bash
# List all available packages contained in $OPT_ROOT/packages.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-list-available"
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

if [ $# -ne 0 ]
then
    usage >&2
    exit 1
fi

# While it might be nice to just list package names, opt-install takes
# .pkg files, not package names, and it's good if the output is something
# that can be passed to opt-install.
/bin/ls -1 $OPT_PKG_DIR/*.pkg 2>/dev/null
