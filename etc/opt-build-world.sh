#! /bin/sh
# Utility script to build the entire world.

set -eu
source $OPT_ROOT/etc/opt/opt-config.sh

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
done < $OPT_ETC_DIR/opt-world.list

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
	    opt-build --install from-scratch $OPT_SPECS_DIR/${pkg_name}.spec
	    ;;
    esac
done < $OPT_ETC_DIR/opt-world.list

date
