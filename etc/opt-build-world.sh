#! /bin/sh
# Utility script to build the entire world.

set -eu
source $OPT_ROOT/etc/opt-config.sh

IFS="
"

# First pass, catch errors in the file.

while read line
do
    case "$line" in
	\#*)
	    ;;
	"" | \ *)
	    ;;
	*)
	    pkg_name="$line"
	    if [ ! -f $OPT_SPECS_DIR/${pkg_name}.spec ]
	    then
		echo "Unknown package: $pkg_name" >&2
		exit 1
	    fi
	    ;;
    esac
done < $OPT_ROOT/etc/opt-world.list

# On with the show.

set -x

while read line
do
    case "$line" in
	\#*)
	    ;;
	"" | \ *)
	    ;;
	*)
	    pkg_name="$line"
	    opt-build from-scratch $OPT_SPECS_DIR/${pkg_name}.spec
	    ;;
    esac
done < $OPT_ROOT/etc/opt-world.list
