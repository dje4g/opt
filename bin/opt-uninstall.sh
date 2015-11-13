#! /bin/sh
# Uninstall an opt package.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-uninstall <pkg-name>"
    echo "       opt-uninstall --help"
}

if [ $# -ne 1 ]
then
    usage >&2
    exit 1
fi

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

pkg_name="$1"

pkg_contents_file="$OPT_DB_DIR/${pkg_name}.contents"

if [ ! -f "$pkg_contents_file" ]
then
    echo "Either package is not installed or not a package." >&2
    exit 1
fi

set -x

cd "$OPT_ROOT"

cat "$pkg_contents_file" | \
    while read f
    do
	[ -f "$f" ] && rm -f -- "$f"
    done

# TODO(dje): Remove directories that are now empty.
