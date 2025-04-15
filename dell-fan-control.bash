#!/bin/bash

# --- Configuration Variables ---
IP="10.1.10.15"         # BMC IP address
USER="root"               # IPMI username
PASS="calvin"        # IPMI password

# --- Check for ipmitool ---
if ! command -v ipmitool &> /dev/null; then
    echo "ipmitool not found. Attempting to install..."

    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y ipmitool
    elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
        sudo dnf install -y ipmitool
    else
        echo "Unsupported OS. Cannot install ipmitool automatically."
        logger -t ipmi-script "ipmitool installation failed: unsupported OS"
        exit 1
    fi

    # Recheck installation
    if ! command -v ipmitool &> /dev/null; then
        echo "ipmitool installation failed."
        logger -t ipmi-script "ipmitool installation failed"
        exit 1
    fi
fi

# --- Set fan override ---
OUTPUT1=$(ipmitool -I lanplus -H "$IP" -U "$USER" -P "$PASS" raw 0x30 0x30 0x01 0x00 2>&1)
EXIT_CODE1=$?

if [[ $EXIT_CODE1 -eq 0 ]]; then
    logger -t ipmi-script "Step 1 succeeded on $IP"
    echo "Step 1 Success: $OUTPUT1"
else
    logger -t ipmi-script "Step 1 failed on $IP: $OUTPUT1"
    echo "Step 1 Error: $OUTPUT1"
    exit $EXIT_CODE1
fi

# --- Set fan speed ---
OUTPUT2=$(ipmitool -I lanplus -H "$IP" -U "$USER" -P "$PASS" raw 0x30 0x30 0x02 0xff 0x26 2>&1)
EXIT_CODE2=$?

if [[ $EXIT_CODE2 -eq 0 ]]; then
    logger -t ipmi-script "Step 2 succeeded on $IP"
    echo "Step 2 Success: $OUTPUT2"
else
    logger -t ipmi-script "Step 2 failed on $IP: $OUTPUT2"
    echo "Step 2 Error: $OUTPUT2"
    exit $EXIT_CODE2
fi
