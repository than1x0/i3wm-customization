#!/bin/bash
# VPN check (tun0 or wg0)
VPN_IP=$(ip -4 addr show tun0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
if [ -z "$VPN_IP" ]; then
    VPN_IP=$(ip -4 addr show wg0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
fi

if [ -n "$VPN_IP" ]; then
    echo "  VPN: $VPN_IP"
    echo "  VPN: $VPN_IP"
    echo "#50FA7B"
    exit 0
fi

# Local IP
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
if [ -n "$LOCAL_IP" ]; then
    echo "  IP: $LOCAL_IP"
    echo "  IP: $LOCAL_IP"
    echo "#8BE9FD"
else
    echo "  Offline"
    echo "  Offline"
    echo "#FF5555"
fi
