This directory contains "opt", in intentionally simple package manager for fnl.
The goal is to have something that can be thrown away once we decide how we
really want to solve this problem.

Missing:
- package verification
- dependencies
They could easily be added, but at some point it might be better to
switch to pacman or whatever.

To use:

bash$ mkdir /data/opt # Or make a symlink from /data/opt to wherever
bash$ cd /data/opt
bash$ tar --strip-components=1 -xf opt-0.1.pkg

Then set up the following environment variables, maybe in /etc/profile:

PATH=$PATH:/data/opt/bin
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/opt/lib:/data/opt/lib64
PKG_CONFIG_LIBDIR=/lib:/usr/lib:/data/opt/lib

At this point, to install a package:

bash$ opt-install /data/opt/packages/my-package-1.23.pkg

===============================================================================

HEADS UP:

The packages aren't made with root permissions.
You may wish to chown -R root.root /data/opt after installing some packages,
but then you'll need to switch to root to install any more packages.
What to do is left up to you.

Resolving dependencies is (currently) left up to you too.

Note that the sudo packages isn't provided with the requisite ownership
and setuid permissions. Fixing that is left the the user post-installation.

For those that read info files, the "dir" file isn't updated after
package installation.
To update it: TODO

===============================================================================

Currently available packages:
[for up to date list, see packages subdir]

autoconf-2.64.pkg
autoconf-2.69.pkg
automake-1.11.1.pkg
automake-1.14.1.pkg
bc-1.06.pkg
binutils-2.24.pkg
bison-3.0.2.pkg
bzip2-1.0.6.pkg
curl-7.45.0.pkg
db.1.85.pkg
dejagnu-1.5.3.pkg
diffutils-3.3.pkg
e2fsprogs-1.42.13.pkg
emacs-git.pkg
expect-5.45.pkg
file-5.25.pkg
findutils-4.5.14.pkg
flex-2.5.39.pkg
gawk-4.0.2.pkg
gcc-4.9.3.pkg
gdb-7.10.pkg
gettext-0.19.6.pkg
git-2.6.1.pkg
glib-2.46.0.pkg
gmp-6.0.0a.pkg
go-1.4.3.pkg
grub-2.02~beta2.pkg
gzip-1.6.pkg
iproute2-4.2.0.pkg
less-451.pkg
libffi-3.2.1.pkg
libtool-2.4.6.pkg
lsof-4.89.pkg
lynx-2.8.7.pkg
m4-1.4.17.pkg
make-3.82.pkg
missing-libc-0.1.pkg
mpc-1.0.2.pkg
mpfr-3.1.2.pkg
native-tools-0.1.pkg
parted-3.2.pkg
patch-2.7.5.pkg
perl-5.22.0.pkg
pkg-config-0.28.pkg
python-2.7.10.pkg
python-3.5.0.pkg
re2c-0.14.3.pkg
readline-6.3.pkg
sed-4.2.2.pkg
strace-4.10.pkg
sudo-1.8.14.pkg
tar-1.28.pkg
tcl-8.5.18.pkg
texinfo-5.2.pkg
vim-7.4.pkg
xz-5.2.2.pkg

