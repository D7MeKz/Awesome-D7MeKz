#!/bin/bash

GOOGLE_DNS="8.8.8.8"
CONFIG_FILE="/etc/resolv-configured.conf"

# Create configured file
echo -e "nameserver $GOOGLE_DNS" >$CONFIG_FILE

# Remove existed resolv.conf
if [ -f /etc/resolv.conf] && [! -L /etc/resolv.conf]; then
    rm /etc/resolv.conf
    echo "Original resolv.conf file removed."
fi

# Symbolic link
ln -s $CONFIG_FILE /etc/resolv.conf
