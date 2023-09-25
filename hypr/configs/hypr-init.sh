#!/bin/bash

# all init commands for hyprland 



# This bit is for connecting to sshfs remote directories

fusermount3 -u /home/user/documents
fusermount3 -u /home/user/programs

# Attempt to mount and log any errors
sshfs user@server:/home/user/documents /home/user/documents 
sshfs user@server:/home/user/programs /home/user/programs 

# Loop 50 times, with a sleep of 0.2s (200ms) between iterations, total 10s
for ((i=0; i<50; i++)); do
    # Check if both directories are mount points
    if mountpoint -q /home/user/documents && mountpoint -q /home/user/programs; then
        notify-send "Successfully connected"
        exit 0
    fi
    # Sleep for 200ms before rechecking
    sleep 0.2
done

# If the loop finishes without exiting, the mount was not successful within the timeout
notify-send "Connection failed"
