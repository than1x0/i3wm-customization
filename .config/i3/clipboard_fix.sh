#!/bin/bash

# Fix clipboard & display synchronization in VMware Workstation / Player
if command -v vmtoolsd >/dev/null 2>&1; then
    pkill vmtoolsd 2>/dev/null
    vmtoolsd -n vmusr &
fi

# Fix clipboard & display synchronization in VirtualBox
if command -v VBoxClient >/dev/null 2>&1; then
    pkill VBoxClient 2>/dev/null
    VBoxClient --clipboard &
    VBoxClient --display &
fi
