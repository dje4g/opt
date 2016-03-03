#! /bin/bash
# Usage: opt-find-strippable-binaries.sh <dir>

set -eu

source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-find-strippable-binaries.sh <dir> [<dir> ...]"
}

error() {
    echo "$@" >&2
    exit 1
}

if [ $# -eq 0 ]
then
    usage >&2
    exit 1
fi

for dir in "$@"
do
    if [ ! -d "$dir" ]
    then
	error "Not a directory: $dir"
    fi
done

for dir in "$@"
do
    find "$dir" -type f -executable -print | \
	while read f
	do
	    case "$(file $f)" in
		*ELF*) echo "$f" ;;
		*) ;;
	    esac
	done
done
