#!/bin/bash
# Disk free space display
avail=$(df -h / | awk 'NR==2 {print $4}')
echo "  Disk: ${avail}"
