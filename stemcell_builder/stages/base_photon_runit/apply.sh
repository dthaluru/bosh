#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

runit_version=runit-2.1.1
run_in_chroot $chroot " 
curl -L http://smarden.org/runit/${runit_version}.tar.gz > /tmp/${runit_version}.tar.gz
tar -C /tmp -xvf /tmp/${runit_version}.tar.gz
cd /tmp/admin/${runit_version}
sh package/install
"

cp $(dirname $0)/assets/runit.service ${chroot}/usr/lib/systemd/system/
run_in_chroot ${chroot} "systemctl enable runit"
run_in_chroot ${chroot} "systemctl enable NetworkManager"
