#! /bin/sh
# Rebuild the info directory (table of contents).

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-rebuild-info-dir"
    echo "       opt-rebuild-info-dir --help|--version"
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
	*)
	    usage >&2
	    exit 1
	    ;;
    esac
fi

if [ $# -ne 0 ]
then
    usage >&2
    exit 1
fi

set -x

declare -r info_dir="$OPT_ROOT/share/info"
rm -f "$info_dir/dir"

for f in "$info_dir"/*.info
do
    install-info --info-dir="$info_dir" --info-file="$f"
done
