This directory contains "opt", an intentionally simple package manager for fnl.
The goal is to have something that can be thrown away once we decide how we
really want to solve this problem.
["opt" for OPTional]

Missing:
- package verification
- dependencies
- it's assumed packages are disjoint
  [not true in case of info/dir, but it needs to be updated after
  install/uninstall anyway]
- remotely fetching packages
- query, even just to display a short description
They could easily be addressed, but at some point it might be better to
switch to pacman or whatever.

WARNING WARNING WARNING: This is all beta software.
The author has used it a lot, but no rigorous testing has been done.
In particular, while some minimal testing of each of the packages has
been done, and the author used all of it to install grub + rootimg
on his pixel2, and then build all of these packages on his pixel2,
heads up.

===============================================================================

To use:
[this is perhaps temporary pending checking some of this in somewhere]

bash$ mkdir /data/opt # Or make a symlink from /data/opt to wherever
bash$ cd /data/opt
bash$ tar --strip-components=1 -z -xf opt-0.1.pkg

Note: tar,gzip don't come with the base image yet.
You can grab them from tar-1.28.pkg,gzip-1.6.pkg and untar it on your desktop
or whatever, and copy it over to a temp place and add it to PATH.
Then once you've installed opt-0.1, properly install tar-1.28.pkg,gzip-1.6.pkg
and then remove the temp place.

Then set up the following environment variables, maybe in /etc/profile:

PATH=$PATH:/data/opt/bin
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/opt/lib:/data/opt/lib64
PKG_CONFIG_LIBDIR=/lib:/usr/lib:/data/opt/lib

At this point, to install a package:

bash$ opt-install /path/to/tar-1.28.pkg
bash$ opt-install /path/to/gzip-1.6.pkg

Packages are canonically kept in /data/opt/packages,
but you can store them wherever and delete them once installed.
One suggestions is to copy the contents of the packages subdirectory here
(on x20) to /data/opt/packages.

The author has recreated /data/opt on the internal drive using the
above procedure and then manually installing every package, so at
least something is working. :-) No longer need my external ssd, yay.
[Though it's useful to still do development there.]

There is opt-uninstall which takes the package name as an argument:

bash$ opt-uninstall my-package-1.23

Other commands are:

bash$ opt-list-installed
bash$ opt-list-available # assumes packages are installed in /data/opt/packages

===============================================================================

Administrivia

The "packages" and "src" subdirectories are images of /data/opt/{packages,src}
on the author's pixel2. If you want to keep things simple, just copy both trees
to /data/opt/{packages,src} on your pixel2.
[Remember /data/opt can be a symlink to anywhere.]

The packages are built "as if" they live in a "/usr/local"-like directory but
outside of the root image: /data/opt.  That is, the root image is treated as
separate, and these packages are intentionally built to not touch the root
image. They're built and installed as user "tq" (uid 1001, gid 1001) so any
accidental modification of the root image will be caught (even if root is
remounted r/w).

gcc+binutils are taught about this "/usr/local" by replacing their internal
knowledge of /usr/local with /data/opt. There are configuration parameters
to do this so it's quite easy. [Though I did have to apply a patch to gcc
to fix a bug in the musl configuration.]

We *could* actually use /usr/local and for those who want to have this stuff
live off of the root partition set up a symlink from /usr/local to /data/opt
(or wherever), but with perhaps an over-abundance of caution I stayed away
from it.

To rebuild a package:

bash$ mkdir /data/opt/staging
bash$ cd /data/opt/staging
bash$ opt-build from-scratch /path/to/my-package-1.23.spec

The output will be /data/opt/packages/my-package-1.23.pkg.

Specs are canonically kept in /data/opt/src/specs, so:

bash$ opt-build from-scratch /data/opt/src/specs/my-package-1.23.spec

This will untar, configure, make, stage in "DESTDIR", and create
my-package-1.23.pkg and install it in /data/opt/packages.

The first argument to opt-build is what to do. The full set of steps are:
prepare -> configure -> make -> stage -> package -> clean.
To simplify things "from-scratch" does all but clean,
and "from-source" is the same as "from-scratch" but starts from "configure",
assuming "prepare" has already been done, and in particular the sources have
already been extracted and patches applied (useful for debugging).

There is a global configuration file for opt: /data/opt/etc/opt-config.sh,
so these locations can be moved, but it's not been tested.

To rebuild the world:

[current directory doesn't matter, everything is built in /data/opt/staging]
bash$ sh /data/opt/etc/opt-build-world.sh

When bootstrapping things it's important to build the world once, install it,
and then build the world again. A lot of "What does this system have?"
determination is done at configure time, and you generally want each package
to assume everything that can be present is actually present.

Note: texinfo and perl builds are a bit flaky. Haven't root-caused it yet.

===============================================================================

HEADS UP

The packages aren't made with root permissions.
You may wish to chown -R root.root /data/opt after installing some packages,
but then you'll need to switch to root to install any more packages.
The author just leaves it all as owned by "tq".
What to do is left up to you.

Resolving dependencies is (currently) left up to you too.

Note that the sudo package isn't provided with the requisite ownership
and setuid permissions. Fixing that is left to the user post-installation.

For those that read info files, the "dir" file isn't updated after
package installation.
To update it: TODO

===============================================================================

Installing the ssl certificates

The package certs-0.1.pkg contains certificates from mozilla.
See README.txt in the source tarball src/tarballs/certs-0.1.tar.gz.

These need to be installed in /etc, not /data/opt/etc, so INSTEAD of:

bash$ opt-install /data/opt/packages/certs-0.1.pkg

do (as root):

# remount # make sure root is mounted r/w
# cd /
# tar --strip-components=1 -z -xf /data/opt/packages/certs-0.1.pkg

===============================================================================

Random thoughts

- Could parallelize world builds more. It'd be simple enough to do with
  ninja or whatever. It might be useful to build packages with a low -jN
  value: I'm not sure how much ninja tracks the load created by its
  subprocesses. There's enough packages to maintain parallelism in a world
  build (though that assumes the bigger packages aren't built last).

- Support for completely cross-building the world (modulo packages that
  have hardwired assumptions about being built natively) is anticipated.
  - maybe have a flag that specifies "requires" native
  - then change std_native_package into std_package and have the latter
    check this flag (will have to special case native builds that are already
    special cased, so no worries there)

===============================================================================

TODO

- elfutils
- kbd
- setuptools (utility for installing python packages, needed to install mako)
- mako (used by mesa, but apparently not necessary)
- llvm

===============================================================================

Currently available packages: See file PACKAGES.txt in this directory.
For an up to date list, see the packages subdir.
