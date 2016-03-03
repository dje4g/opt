#! /bin/bash
# Main script for building packages.
#
# Functions beginning with pkg_ are for packages to redefine if needed.

set -eu

case "$0" in
/*) declare -r OPT_ROOT=$(dirname $(dirname $0)) ;;
*) declare -r OPT_ROOT=$(dirname $(dirname $(pwd)/$0)) ;;
esac
source $OPT_ROOT/etc/opt/opt-config.sh

usage() {
    echo "Usage: opt-build [options] <mode> <spec-file>"
    echo "Options:"
    echo "  --install"
    echo "Mode is one of:"
    echo "  help"
    # TODO(dje): It might be useful to split up prepare into prepare, extract.
    # "source" is a synonym for "prepare": for installing the "source" package
    echo "  prepare [or source]"
    echo "  configure"
    echo "  make"
    echo "  stage"
    echo "  sysroot"
    echo "  package"
    echo "  clean"
    echo "  from-scratch"
    echo "  from-source"
}

error() {
    echo "$@" >&2
    exit 1
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
    esac
fi

do_install=no

done_options=no
while [ $# -gt 0 -a $done_options = no ]
do
    case "$1" in
	--install) do_install=yes ; shift ;;
	-*) usage >&2 ; exit 1 ;;
	*) done_options=yes ;;
    esac
done

if [ $# -ne 2 ]
then
    usage >&2
    exit 1
fi

mode="$1"
OPTPKG_SPECFILE="$2"

if [ ! -f "$OPTPKG_SPECFILE" ]
then
    echo "Spec file non-existent: $OPTPKG_SPECFILE" >&2
    exit 1
fi

case "$mode" in
    help)
	usage
	exit 0
	;;
    prepare | source | configure | make | stage | sysroot | package | clean)
	;;
    from-scratch | from-source)
	;;
    *)
	echo "Unknown mode: $mode" >&2
	usage >&2
	exit 1
	;;
esac

rqst_prepare=no
rqst_configure=no
rqst_make=no
rqst_stage=no
rqst_sysroot=no
rqst_package=no
rqst_clean=no

case "$mode" in
    prepare) rqst_prepare=yes ;;
    source) rqst_prepare=yes ;;
    configure) rqst_configure=yes ;;
    make) rqst_make=yes ;;
    stage) rqst_stage=yes ;;
    sysroot) rqst_sysroot=yes ;;
    package) rqst_package=yes ;;
    clean) rqst_clean=yes ;;
    from-source | from-scratch)
	rqst_configure=yes
	rqst_make=yes
	rqst_stage=yes
	rqst_package=yes
	;;
esac

case "$mode" in
    from-scratch) rqst_prepare=yes ;;
esac

# Validate any options.

if [ $do_install = yes -a $rqst_package = no ]
then
    error "--install requires building the package"
fi

# Any final setup.

case "$OPT_BUILD_SYSTEM" in
    *-linux-musl)
	#export PATH="$OPT_SYSROOT_DIR/bin:$PATH"
	set +u
	if [ -z "$LD_LIBRARY_PATH" ]
	then
	    export LD_LIBRARY_PATH="$OPT_SYSROOT_DIR/lib"
	else
	    export LD_LIBRARY_PATH="$OPT_SYSROOT_DIR/lib:$LD_LIBRARY_PATH"
	fi
	pkg_config_libdir="/lib/pkgconfig:/usr/lib/pkgconfig:$OPT_ROOT/lib/pkgconfig"
	if [ -z "$PKG_CONFIG_LIBDIR" ]
	then
	    export PKG_CONFIG_LIBDIR="$pkg_config_libdir"
	else
	    export PKG_CONFIG_LIBDIR="$pkg_config_libdir:$PKG_CONFIG_LIBDIR"
	fi
	declare -r OPTPKG_BUILD_SYSROOT_OPTION=
	set -u
	;;
    *)
	set +u
	pkg_config_libdir="$OPT_SYSROOT_DIR/lib/pkgconfig:$OPT_SYSROOT_DIR/usr/lib/pkgconfig:$OPT_ROOT/lib/pkgconfig"
	if [ -z "$PKG_CONFIG_LIBDIR" ]
	then
	    export PKG_CONFIG_LIBDIR="$pkg_config_libdir"
	else
	    export PKG_CONFIG_LIBDIR="$pkg_config_libdir:$PKG_CONFIG_LIBDIR"
	fi
	declare -r OPTPKG_BUILD_SYSROOT_OPTION=--with-sysroot=$OPT_SYSROOT_DIR
	set -u
	;;
esac

# Utility functions.

analyze_spec() {
    set -x

    # Part of what this does is make sure these variables are defined.
    : "Package $PKG_NAME ..."
    : "Version $PKG_VERSION ..."
    : "Tarball $PKG_TARBALL ..."
    : "URL $PKG_URL ..."

    # These are optional, provide defaults.
    set +u
    if [ -z "$PKG_SIG" ]
    then
	# This works for gnu packages, and there are a lot of them,
	# so this is as good a default as any.
	declare -g -r PKG_SIG=${PKG_URL}.sig
    fi
    if [ -z "$PKG_SRC" ]
    then
	declare -g -r PKG_SRC=${PKG_NAME}-${PKG_VERSION}
    fi
    if [ -z "$PKG_PATCHES" ]
    then
	declare -g -r PKG_PATCHES=none
    fi
    if [ -z "$PKG_BUILD_IN_SRC" ]
    then
	declare -g -r PKG_BUILD_IN_SRC=no
    fi
    if [ -z "$PKG_NATIVE_ONLY" ]
    then
	declare -g -r PKG_NATIVE_ONLY=no
    fi
    set -u
    : "Signature $PKG_SIG ..."
    : "Source $PKG_SRC ..."
    : "Patches $PKG_PATCHES ..."
    : "Build-in-src $PKG_BUILD_IN_SRC ..."
    : "Native-only $PKG_NATIVE_ONLY ..."

    # Export these for programs like opt-apply-patches.
    export PKG_NAME
    export PKG_VERSION
    export PKG_TARBALL
    export PKG_URL
    export PKG_SIG
    export PKG_SRC
    export PKG_PATCHES
    export PKG_BUILD_IN_SRC
    export PKG_NATIVE_ONLY

    # Exported utility variables, to simplify the text.
    declare -g -r OPTPKG_FULLNAME=${PKG_NAME}-${PKG_VERSION}
    declare -g -r OPTPKG_SRCDIR=$OPT_STAGE_DIR/src/$OPTPKG_FULLNAME
    declare -g -r OPTPKG_BUILDDIR=$OPT_STAGE_DIR/build/$OPTPKG_FULLNAME
    declare -g -r OPTPKG_DESTDIR=$OPT_STAGE_DIR/destdir/$OPTPKG_FULLNAME
    declare -g -r OPTPKG_DEBUG_DESTDIR=$OPT_STAGE_DIR/debug-destdir/$OPTPKG_FULLNAME
    export OPTPKG_FULLNAME
    export OPTPKG_SRCDIR
    export OPTPKG_BUILDDIR
    export OPTPKG_DESTDIR
    export OPTPKG_DEBUG_DESTDIR

    set +x
}

prepare_package() {
    if [ "$rqst_prepare" = yes ]
    then
	set -x
	cd $OPT_STAGE_DIR
	rm -rf $OPTPKG_SRCDIR
	mkdir -m 0755 -p $OPTPKG_SRCDIR
	tar -C $OPTPKG_SRCDIR -xf $OPT_SRC_DIR/$PKG_TARBALL
	if [ "$PKG_PATCHES" != "none" ]
	then
	    /bin/bash $OPT_ROOT/etc/opt/opt-apply-patches.sh $OPT_PATCHES_DIR/$PKG_PATCHES $OPTPKG_SRCDIR/$PKG_SRC
	fi
	set +x
    fi
}

prepare_build_dir() {
    # One could pass in the build dir, but these are fixed state variables.
    cd $OPT_STAGE_DIR
    rm -rf $OPTPKG_BUILDDIR
    mkdir -m 0755 -p $OPTPKG_BUILDDIR
}

# gmp complains if --target is specified.
# See if we can get away with not specifying target at all.
# It's the same as --host.
#
# An alternative to CFLAGS is to use install-strip, but not every package has
# install-strip, and we generally don't need debug info.
# CFLAGS is set for configure and make because some packages handle one or
# the other.

std_cross_configure() {
    $OPTPKG_SRCDIR/$PKG_SRC/configure \
	--build=$OPT_BUILD_SYSTEM \
	--host=$OPT_HOST_SYSTEM \
	--prefix=$OPT_ROOT \
	$OPTPKG_BUILD_SYSROOT_OPTION \
	--disable-nls \
	--enable-shared \
	CFLAGS="-g -O2" CXXFLAGS="-g -O2" \
	"$@"
}

# Bleah, some packages use AC_TRY_RUN, and thus require a native build.
# The use of OPT_NATIVE_SYSTEM instead of OPT_BUILD_SYSTEM is a quirk of
# our self-hosted cross builds.

std_native_configure() {
    $OPTPKG_SRCDIR/$PKG_SRC/configure \
	--build=$OPT_NATIVE_SYSTEM \
	--host=$OPT_NATIVE_SYSTEM \
	--prefix=$OPT_ROOT \
	--disable-nls \
	--enable-shared \
	CFLAGS="-g -O2" CXXFLAGS="-g -O2" \
	"$@"
}

std_configure() {
    if [ "$PKG_NATIVE_ONLY" = yes ]
    then
	std_native_configure "$@"
    else
	std_cross_configure "$@"
    fi
}

pkg_configure() {
    std_configure
}

run_configure() {
    if [ "$rqst_configure" = yes ]
    then
	set -x
	if [ "$PKG_BUILD_IN_SRC" = yes ]
	then
	    cd $OPTPKG_SRCDIR/$PKG_SRC
	else
	    prepare_build_dir
	    cd $OPTPKG_BUILDDIR
	fi
	pkg_configure
	set +x
    fi
}

std_make() {
    make -j$OPT_PARALLELISM \
	CFLAGS="-g -O2" CXXFLAGS="-g -O2" \
	"$@"
}

pkg_make() {
    std_make
}

run_make() {
    if [ "$rqst_make" = yes ]
    then
	set -x
	if [ "$PKG_BUILD_IN_SRC" = yes ]
	then
	    cd $OPTPKG_SRCDIR/$PKG_SRC
	else
	    cd $OPTPKG_BUILDDIR
	fi
	pkg_make
	set +x
    fi
}

build_contents_file() {
    mkdir -m 0755 -p ${OPTPKG_DESTDIR}${OPT_DB_DIR}/pkg
    # IWBN to exclude directories from the list to simplify collision
    # detection but that would remove empty directories.
    (cd ${OPTPKG_DESTDIR}${OPT_ROOT} && find . -print) > ${OPTPKG_DESTDIR}${OPT_DB_DIR}/pkg/${OPTPKG_FULLNAME}.contents
}

std_stage() {
    make install "$@"
}

pkg_stage() {
    std_stage "$@"
}

run_stage() {
    if [ "$rqst_stage" = yes ]
    then
	set -x
	if [ "$PKG_BUILD_IN_SRC" = yes ]
	then
	    cd $OPTPKG_SRCDIR/$PKG_SRC
	else
	    cd $OPTPKG_BUILDDIR
	fi
	rm -rf $OPTPKG_DESTDIR
	# Pass DESTDIR as both an env var and make var for convenience.
	export DESTDIR=$OPTPKG_DESTDIR
	pkg_stage DESTDIR=$OPTPKG_DESTDIR
	unset DESTDIR
	build_contents_file
	set +x
    fi

    # See if we're to stage the package in sysroot.

    if [ "$rqst_sysroot" = yes ]
    then
	set -x
	if [ "$PKG_BUILD_IN_SRC" = yes ]
	then
	    cd $OPTPKG_SRCDIR/$PKG_SRC
	else
	    cd $OPTPKG_BUILDDIR
	fi
	# Pass DESTDIR as both an env var and make var for convenience.
	export DESTDIR=$OPT_SYSROOT_DIR
	pkg_stage DESTDIR=$OPT_SYSROOT_DIR
	unset DESTDIR
	set +x
    fi
}

build_debug_contents_file() {
    mkdir -m 0755 -p ${OPTPKG_DEBUG_DESTDIR}${OPT_DB_DIR}/dpkg
    # IWBN to exclude directories from the list to simplify collision
    # detection but that would remove empty directories.
    (cd ${OPTPKG_DEBUG_DESTDIR}${OPT_ROOT} && find . -print) > ${OPTPKG_DEBUG_DESTDIR}${OPT_DB_DIR}/dpkg/${OPTPKG_FULLNAME}.contents
}

stage_debug_package() {
    rm -rf $OPTPKG_DEBUG_DESTDIR
    mkdir -m 0755 -p ${OPTPKG_DEBUG_DESTDIR}${OPT_DEBUG_DIR}${OPT_ROOT}
    # Create an image of the installed tree with debug files only,
    # living in the expected location. And then strip everything in the
    # original tree.
    binaries=$(mktemp)
    cd ${OPTPKG_DESTDIR}${OPT_ROOT}
    /bin/bash $OPT_ETC_DIR/opt-find-strippable-binaries.sh . > $binaries
    if [ ! -s $binaries ]
    then
	rm -f $binaries
	return
    fi
    cat $binaries \
    | while read f
    do
	/bin/bash $OPT_ETC_DIR/opt-split-debug.sh . "$f" ${OPTPKG_DEBUG_DESTDIR}${OPT_DEBUG_DIR}${OPT_ROOT}
    done
    cat $binaries \
    | while read f
    do
	${OPT_HOST_SYSTEM}-strip -g "$f"
    done
    build_debug_contents_file
    rm -f $binaries
}

finish_package() {
    if [ "$rqst_package" = yes ]
    then
	set -x
	mkdir -m 0755 -p $OPTSTAGE_PKG_DIR
	declare -r pkg_file=${OPTSTAGE_PKG_DIR}/${OPTPKG_FULLNAME}.pkg
	declare -r debug_pkg_file=${OPTSTAGE_PKG_DIR}/${OPTPKG_FULLNAME}.dpkg
	rm -f $pkg_file $debug_pkg_file
	stage_debug_package
	# Prepend a leading unique directory so that trying to install in /
	# will break. It *could* work, but it doesn't feel safe to allow this
	# by default. The user can always pass --strip-components=1 to tar.
	tar -C ${OPTPKG_DESTDIR}${OPT_ROOT} --transform="s,^[.]/,opt/," -z -cf $pkg_file .
	if [ -d ${OPTPKG_DEBUG_DESTDIR}${OPT_DB_DIR}/dpkg ]
	then
	    tar -C ${OPTPKG_DEBUG_DESTDIR}${OPT_ROOT} --transform="s,^[.]/,opt/," -z -cf $debug_pkg_file .
	fi
	if [ $do_install = yes ]
	then
	    opt-install $pkg_file
	fi
	set +x
    fi

    if [ "$rqst_clean" = yes ]
    then
	set -x
	cd $OPT_STAGE_DIR
	rm -rf $OPTPKG_SRCDIR
	rm -rf $OPTPKG_BUILDDIR
	rm -rf $OPTPKG_DESTDIR
	rm -rf $OPTPKG_DEBUG_DESTDIR
	set +x
    fi
}

std_package() {
    # All builds begin with this.
    prepare_package

    run_configure
    run_make
    run_stage

    # And end with this.
    finish_package
}

# Load the spec file and process the request.

source "$OPTPKG_SPECFILE"
analyze_spec

echo "Beginning build of $OPTPKG_FULLNAME ..."

start_time=$(date '+%s')

std_package

end_time=$(date '+%s')

echo "Build of $OPTPKG_FULLNAME completed in $(expr $end_time - $start_time) seconds."
