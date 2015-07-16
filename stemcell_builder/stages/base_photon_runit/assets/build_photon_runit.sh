#!/bin/sh

whereami=$(dirname $0)

if [ ! -f "/etc/rpm/macros" ];   then echo "please install 'macros' rpm and try again" ; exit 1 ; fi
if [ ! -f "$(which rpmbuild)" ];         then echo "please install 'rpm-build' rpm and try again" ; exit 1 ; fi


RPMDIR=`rpm --eval "%{_rpmdir}"`
SRCDIR=`rpm --eval "%{_sourcedir}"`
SPECDIR=`rpm --eval "%{_specdir}"`
SRPMDIR=`rpm --eval "%{_srcrpmdir}"`
BUILDDIR=`rpm --eval "%{_builddir}"`

mkdir -p $SRCDIR
mkdir -p $SPECDIR
cp -f ${whereami}/runit.spec $SPECDIR
cp -f ${whereami}/*.patch $SRCDIR

runit_version=runit-2.1.1
curl -L http://smarden.org/runit/${runit_version}.tar.gz > $SRCDIR/${runit_version}.tar.gz
rpmbuild -ba $SPECDIR/runit.spec