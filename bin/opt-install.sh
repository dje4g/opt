#! /bin/sh
# Install an opt package.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-install <pkg>"
    echo "       opt-install --help"
    echo "<pkg> must be an opt package file, foo.pkg."
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

opt_file="$1"

case "$opt_file" in
    *.pkg) ;;
    *)
	echo "Not an opt package: $opt_file" >&2
	exit 1
	;;
esac

set -x

tar -C "$OPT_ROOT" --strip-components=1 \
    --preserve-permissions \
    -z -xf "$opt_file"

set +x

# Final sanity check.

pkg_name=$(basename ${opt_file} .pkg)
if [ ! -f "$OPT_DB_DIR/${pkg_name}.contents" ]
then
    echo "WARNING: Missing contents file from package." >&2
fi

echo "Package ${pkg_name} successfully installed."
