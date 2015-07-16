#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

runit_version=runit-2.1.1
if ! pkg_exists ${runit_version}; then
cookbook_release=1.2.0
run_in_chroot $chroot "
curl -L https://github.com/opscode-cookbooks/runit/archive/v${cookbook_release}.tar.gz > /tmp/v${cookbook_release}.tar.gz
tar -C /tmp -xvf /tmp/v${cookbook_release}.tar.gz
tar -C /tmp -xvf /tmp/runit-${cookbook_release}/files/default/${runit_version}.tar.gz
"
cp $(dirname $0)/assets/build_photon_runit.sh $chroot/tmp/${runit_version}/
chmod +x $chroot/tmp/${runit_version}/build_photon_runit.sh
run_in_chroot $chroot "
cd /tmp/${runit_version}
./build_photon_runit.sh
rpm -i /usr/src/photon/RPMS/${runit_version}.rpm || true
echo "after rpm installation"
"

fi
cp $(dirname $0)/assets/runit.service ${chroot}/usr/lib/systemd/system/
run_in_chroot ${chroot} "systemctl enable runit"
run_in_chroot ${chroot} "systemctl enable NetworkManager"
