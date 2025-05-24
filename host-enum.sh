#!/bin/bash

# Verifying nmap installation
if ! command -v nmap &> /dev/null; then
    echo "ERROR: Nmap not installed."
    exit 1
fi

# Enum host
if [ -z "$1" ]; then
    echo "Use $0 <network ip>"
    echo "Example: $0 192.168.0.0/24"
    exit 1
fi

NETWORK=$1

# Checking CIDR notation using regex
if [[ ! "$NETWORK" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    echo "ERROR: Please use CIDR notation. Example: 0.0.0.0/0"
    exit 1
fi

echo "Scanning network $NETWORK. Searching for active hosts"
nmap -sn $NETWORK | grep "Nmap scan report for" | awk '{print $5}' > active_hosts.txt

# Checking file and if has content
if [ -s active_hosts.txt ]; then
    echo "Nmap has detect active hosts. Please check'em in active_hosts.txt"
else
    echo "No file found!"
fi
