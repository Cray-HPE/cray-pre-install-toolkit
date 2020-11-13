#!/usr/bin/env bash
# greps 'ip link show' output for argument
# arg 1: interface ID (ex: vlan004, bond0, etc.)

ip link show | grep -e "[0-9]*: $1"

exit