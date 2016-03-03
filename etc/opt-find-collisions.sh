#! /bin/bash
# Scan packages for collisions.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $(dirname $0))) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(dirname $(pwd)/$0))) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-find-collisions"
    echo "       opt-find-collisions --help|--version"
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

# Assume there are no collisions, and then if there are do extra work
# to find the culprits.

all_files=$(mktemp)
sorted_all_files=$(mktemp)
all_collisions=$(mktemp)
trap "rm -f $all_files $sorted_all_files $all_collisions" EXIT

for c in $OPT_DB_DIR/*.contents
do
    cat "$c" >> "$all_files"
done

sort "$all_files" > "$sorted_all_files"

if [ '$(wc - < "$all_files")' == '$(uniq "$sorted_all_files" | wc -)' ]
then
    exit 0
fi

echo "Collision(s) detected ..."

uniq --repeated "$sorted_all_files" > "$all_collisions"

for f in $(cat $all_collisions)
do
    # We leave directories in contents files, so first remove those,
    # they aren't real collisions
    if [ -d "$OPT_ROOT/$f" ]
    then
	continue
    fi

    # Collisions on these files is expected.
    case "$f" in
    "./share/info/bfd.info") ;;
    "./share/info/dir") ;;
    "./share/info/standards.info") ;;
    *) echo "$f" ;;
    esac
done

exit 1
