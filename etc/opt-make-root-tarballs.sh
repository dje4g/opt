#! /bin/bash
# Make tarballs of packages in the root image.

set -eu
set -x

cd /sam/tqdata/rtq/staging

tar --transform="s,^gcc/,gcc-4.9.3/," \
    --exclude='gcc/.jiri/*' --exclude='gcc/.jiri' \
    --exclude='gcc/.git/*' --exclude='gcc/.git' \
    -z -cf /data/opt/packages/src/gcc-4.9.3.tar.gz gcc

#cp toolchain/tarballs/*.tar.* /data/opt/packages/src
