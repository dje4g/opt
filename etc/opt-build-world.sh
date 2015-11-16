#! /bin/sh
# Utility script to build the entire world.

set -eu
source $OPT_ROOT/etc/opt/opt-config.sh

IFS="
"

WORLD_LIST=$OPT_ROOT/src/opt-world.list

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
done < $WORLD_LIST

# On with the show.

set -x

date

while read line
do
    case "$line" in
	\#*)
	    ;;
	"" | \ *)
	    ;;
	*)
	    pkg_name="$line"
	    # The next package may need this one, so tell opt-build to
	    # install it.
	    # TODO: Install into a staging sysroot.
	    opt-build --install from-scratch $OPT_SPECS_DIR/${pkg_name}.spec
	    ;;
    esac
done < $WORLD_LIST

date
