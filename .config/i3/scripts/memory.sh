#!/bin/bash
# Clean RAM usage display
free -m | awk '
/Mem:/ {
    used=$3/1024
    total=$2/1024
    printf "  RAM: %.1fG/%.1fG\n", used, total
}'
