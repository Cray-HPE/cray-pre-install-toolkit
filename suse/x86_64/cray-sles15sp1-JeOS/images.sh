#!/bin/sh
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

echo "Configure image: [$kiwi_iname]..."

#==========================================
# setup build day
#------------------------------------------
baseSetupBuildDay

#==========================================
# umount
#------------------------------------------
umount /proc >/dev/null 2>&1

exit 0
