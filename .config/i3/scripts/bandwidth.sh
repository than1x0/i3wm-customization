#!/bin/bash
# High-precision bandwidth calculation using /dev/shm cache (Instant execution, no sleep)

# 1. Identify active interface dynamically
IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')
if [ -z "$IFACE" ]; then
    IFACE=$(ip link | awk -F: '$2 ~ /eth|ens|enp|wlan/ {gsub(/ /,"",$2); print $2; exit}')
fi

if [ -z "$IFACE" ] || [ ! -d "/sys/class/net/$IFACE" ]; then
    echo "  Net: Down"
    exit 0
fi

RX_PATH="/sys/class/net/$IFACE/statistics/rx_bytes"
TX_PATH="/sys/class/net/$IFACE/statistics/tx_bytes"

NOW_RX=$(cat "$RX_PATH" 2>/dev/null || echo 0)
NOW_TX=$(cat "$TX_PATH" 2>/dev/null || echo 0)
NOW_TIME=$(date +%s)

STATE_FILE="/dev/shm/i3blocks_net_${IFACE}"

if [ -f "$STATE_FILE" ]; then
    read -r PREV_TIME PREV_RX PREV_TX < "$STATE_FILE"
    TIME_DIFF=$((NOW_TIME - PREV_TIME))
    if [ "$TIME_DIFF" -gt 0 ]; then
        RX_SPEED=$(( (NOW_RX - PREV_RX) / TIME_DIFF ))
        TX_SPEED=$(( (NOW_TX - PREV_TX) / TIME_DIFF ))
    else
        RX_SPEED=0
        TX_SPEED=0
    fi
else
    RX_SPEED=0
    TX_SPEED=0
fi

echo "$NOW_TIME $NOW_RX $NOW_TX" > "$STATE_FILE"

format_speed() {
    local b=$1
    if [ "$b" -ge 1048576 ]; then
        awk -v bytes="$b" 'BEGIN {printf "%.1f MB/s", bytes/1048576}'
    elif [ "$b" -ge 1024 ]; then
        awk -v bytes="$b" 'BEGIN {printf "%.1f KB/s", bytes/1024}'
    else
        echo "${b} B/s"
    fi
}

RX_F=$(format_speed "$RX_SPEED")
TX_F=$(format_speed "$TX_SPEED")

echo "  ${IFACE}:  ${RX_F}  ${TX_F}"
