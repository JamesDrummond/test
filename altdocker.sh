#!/bin/sh
## name: altdocker.sh
set -e -x
: ${bridge=altdocker}
: ${base=$HOME/$bridge}
# Set up bridge network:
if ! ip link show $bridge > /dev/null 2>&1
then
   sudo brctl addbr $bridge
   sudo ip addr add ${net:-"10.20.30.1/24"} dev $bridge
   sudo ip link set dev $bridge up
fi
sudo docker daemon \
  --bridge=$bridge \
  --exec-root=$base.exec \
  --graph=$base.graph \
  --host=unix://$base.socket \
  --pidfile=$base.pid
