#! /bin/sh
# Usage: opt-apply-patches.sh <patch-spec-file> <src-dir>

set -eu

source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-apply-patches.sh <patch-spec-file> <src-dir>"
}

if [ $# -ne 2 ]
then
    usage >&2
    exit 1
fi

patch_spec_file="$1"
src_dir="$2"

if [ ! -f "$patch_spec_file" ]
then
    echo "Not a file: $patch_spec_file" >&2
    exit 1
fi

if [ ! -d "$src_dir" ]
then
    echo "Not a directory: $src_dir" >&2
    exit 1
fi

IFS="
"

# Don't do anything until we have some confidence of a valid file.

while read line
do
    case "$line" in
	\#*)
	    ;;
	replace:*)
	    old_IFS="$IFS"
	    IFS=" "
	    set $(echo $line | sed -e s'/:/ /g')
	    IFS="$old_IFS"
	    src_file="$OPT_PATCHES_DIR/$2"
	    dest_file="$src_dir/$3"
	    if [ ! -f "$src_file" ]
	    then
		echo "Bad patch entry, no such src file: \"$line\"" >&2
		exit 1
	    fi
	    if [ ! -f "$dest_file" ]
	    then
		echo "Bad patch entry, no such dest file: \"$line\"" >&2
		exit 1
	    fi
	    ;;
	patch:*)
	    old_IFS="$IFS"
	    IFS=" "
	    set $(echo $line | sed -e s'/:/ /g')
	    IFS="$old_IFS"
	    patch_file="$OPT_PATCHES_DIR/$2"
	    if [ ! -f "$patch_file" ]
	    then
		echo "Bad patch entry, no such patch file: \"$line\"" >&2
		exit 1
	    fi
	    ;;
	command:*)
	    ;;
	"" | \ *)
	    ;;
	*)
	    echo "Bad line in patch file: \"$line\"" >&2
	    exit 1
	    ;;
    esac
done < $patch_spec_file

# On with the show.

while read line
do
    case "$line" in
	\#*) ;;
	replace:*)
	    old_IFS="$IFS"
	    IFS=" "
	    set $(echo $line | sed -e s'/:/ /g')
	    IFS="$old_IFS"
	    src_file="$OPT_PATCHES_DIR/$2"
	    dest_file="$src_dir/$3"
	    set -x
	    cp --verbose "$src_file" "$dest_file"
	    set +x
	    ;;
	patch:*)
	    old_IFS="$IFS"
	    IFS=" "
	    set $(echo $line | sed -e s'/:/ /g')
	    IFS="$old_IFS"
	    patch_file="$OPT_PATCHES_DIR/$2"
	    set -x
	    patch -d $OPTPKG_SRCDIR/$PKG_SRC -p1 < $patch_file
	    set +x
	    ;;
	command:*)
	    (
		old_IFS="$IFS"
		IFS=" "
		set $(echo $line | sed -e s'/:/ /g')
		IFS="$old_IFS"
		shift
		command="$@"
		set -eux
		cd $OPTPKG_SRCDIR/$PKG_SRC
		/bin/sh -c "$command"
	    ) || exit 1
	    ;;
	"" | \ *)
	    ;;
    esac
done < $patch_spec_file

echo "Done applying patches from $patch_spec_file to $src_dir."
