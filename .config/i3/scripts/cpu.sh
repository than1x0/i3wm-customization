#!/bin/bash
# Accurate CPU calculation via /proc/stat
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total_1=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_1=$((idle + iowait))

sleep 0.2

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total_2=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_2=$((idle + iowait))

total_diff=$((total_2 - total_1))
idle_diff=$((idle_2 - idle_1))

if [ "$total_diff" -gt 0 ]; then
    usage=$(( 100 * (total_diff - idle_diff) / total_diff ))
    echo "  CPU: ${usage}%"
else
    echo "  CPU: 0%"
fi
