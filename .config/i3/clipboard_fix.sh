#!/bin/bash

# ==============================================================================
# VM Synchronization, Clipboard, Display & Screen Saver Fix
# Prevents VMware & VirtualBox screen blackouts, clipboard loss, and sleep issues
# ==============================================================================

# 1. Fix clipboard & display synchronization in VMware Workstation / Player
if command -v vmtoolsd >/dev/null 2>&1; then
    pkill vmtoolsd 2>/dev/null || true
    vmtoolsd -n vmusr &
fi

# 2. Fix clipboard & display synchronization in VirtualBox
if command -v VBoxClient >/dev/null 2>&1; then
    pkill VBoxClient 2>/dev/null || true
    VBoxClient --clipboard &
    VBoxClient --display &
fi

# 3. Disable X11 Screen Blanking, Screensaver & DPMS Sleep (Prevents VM Black Screen)
if command -v xset >/dev/null 2>&1; then
    xset s off 2>/dev/null || true
    xset -dpms 2>/dev/null || true
    xset s noblank 2>/dev/null || true
    xset s 0 0 2>/dev/null || true
fi

# 4. Disable XFCE Power Manager display sleep/blanking if present in background
if command -v xfconf-query >/dev/null 2>&1; then
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false 2>/dev/null || true
fi

# 5. Disable light-locker daemon if active in background
pkill -f light-locker 2>/dev/null || true
