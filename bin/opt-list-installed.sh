#! /bin/sh
# List all installed packages.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-list-installed"
}

if [ $# -eq 0 -a "$1" == --help ]
then
    usage
    exit 0
fi

if [ $# -ne 0 ]
then
    usage >&2
    exit 1
fi

cd $OPT_DB_DIR
/bin/ls -1 *.contents 2>/dev/null | sed -e 's/[.]contents$//'
