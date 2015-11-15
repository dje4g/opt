# Define various environment variables that configure "opt".

OPT_VERSION="0.2.90"

# The root of the opt tree.
# OPT_ROOT is either auto-determined or set by the user, and then compared
# with this as a sanity check.
declare -r OPT_CONFIGURED_ROOT=/data/opt

# The cd/pwd thing is to handle symlinks.
if [ "$(cd $OPT_ROOT && /bin/pwd -P)" != "$(cd $OPT_CONFIGURED_ROOT && pwd -P)" ]
then
    # Running from the source tree?
    if [ -f "$OPT_ROOT"/Makefile.in ]
    then
	echo "WARNING: Running from the build tree." >&2
    else
	echo "Installation sanity check error." >&2
	echo "OPT_ROOT: $OPT_ROOT" >&2
	echo "OPT_CONFIGURED_ROOT: $OPT_CONFIGURED_ROOT" >&2
	exit 1
    fi
fi

# The etc dir.
declare -r OPT_ETC_DIR=$OPT_ROOT/etc/opt

# The main working directory.
declare -r OPT_STAGE_DIR=$OPT_ROOT/staging

# Where packages get put by opt-build.
declare -r OPTSTAGE_PKG_DIR=$OPT_STAGE_DIR/packages

# sysroot in the staging area.
declare -r OPT_SYSROOT_DIR=$OPT_STAGE_DIR/sysroot
declare -r OPT_SYSROOT_ROOT=${OPT_SYSROOT_DIR}${OPT_ROOT}

# Where package src tarballs live.
declare -r OPT_SRC_DIR=$OPT_ROOT/src/tarballs

# Where package patches live.
declare -r OPT_PATCHES_DIR=$OPT_ROOT/src/patches

# Where package specs live.
declare -r OPT_SPECS_DIR=$OPT_ROOT/src/specs

# Where packages get put.
declare -r OPT_PKG_DIR=$OPT_ROOT/packages

# Where we record details of packages.
declare -r OPT_DB_DIR=$OPT_ROOT/var/opt

# The build/host/target triplets.
# For non-crosstools host == target.
# For crosstools host == build, target != host.
# TODO: Obviously needs to be configurable.
declare -r OPT_BUILD_SYSTEM=x86_64-fuchsiabuild-linux-musl
declare -r OPT_HOST_SYSTEM=x86_64-fuchsia-linux-musl

# This is for native builds.
# We'd like to use OPT_BUILD_SYSTEM, but that's taken for self-hosted
# cross builds.
# MACHTYPE is provided by bash.
declare -r OPT_NATIVE_SYSTEM=$MACHTYPE

# The -j arg to make.
declare -r OPT_PARALLELISM=8

# The main gnu ftp directory.
declare -r OPT_URL_GNU=ftp://ftp.gnu.org/gnu

opt_print_version() {
    echo "OPT version $OPT_VERSION."
}
