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
install -d -m 0755 /etc/service
install -D -m 0750 etc/2 /usr/sbin/runsvdir-start
"
for i in $(< ${chroot}/tmp/admin/${runit_version}/package/commands) ; do
install -D -m 0755 ${chroot}/tmp/admin/${runit_version}/command/$i  ${chroot}/usr/sbin/$i
done
for i in ${chroot}/tmp/admin/${runit_version}/man/*8 ; do
install -D -m 0755 $i  ${chroot}/usr/share/man/man8/${i##man/}
done

cp $(dirname $0)/assets/runit.service ${chroot}/usr/lib/systemd/system/
install -D -p -m 0644 $(dirname $0)/assets/runsvdir-start.service ${chroot}/usr/lib/systemd/system/runsvdir-start.service

run_in_chroot ${chroot} "systemctl enable runit"
run_in_chroot ${chroot} "systemctl enable NetworkManager"
