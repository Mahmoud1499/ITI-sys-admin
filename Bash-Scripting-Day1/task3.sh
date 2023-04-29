#!/bin/bash

## Script to monitor system load, and add it to file /var/log/system-load
# The script runs an infinite loop using the while command.

## Exit codes
##	0: Success
##	1: This script must be run as root

# Check if the script is being run as root
[ "$(id -u)" -eq 0 ] || {
    echo "This script must be run as root."
    exit 1
}
while true; do

    # Get the current system load
    LOAD=$(uptime | awk '{print $10}')

    # Get the current date and time
    DATE=$(date '+%Y-%m-%d %H:%M:%S')

    # Write the system load and date/time to the log file
    echo "[$DATE] System load: $LOAD" >>/var/log/system-load

    # Wait for 10 seconds before checking the load again
    sleep 10
done

exit 0
