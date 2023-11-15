#!/bin/bash

###############################################################
# Updated 2023-11-14 by Neil Poulin
# This script runs via Kandji to install the langston CLI
###############################################################

echo "whoami: $(whoami)"

# Determine the current user
current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')

# Create a temporary directory in the user home directory

temp_dir="/Users/$current_user/langston-cli-tmp"
mkdir -p "$temp_dir"
echo "Temporary directory created: $temp_dir"

# URL of the script to download
script_url="https://raw.githubusercontent.com/the-langston-co/langston-cli/main/bin/scripts/configure/download.sh"

# Download the script
echo "Downloading the script..."
curl -s -o "$temp_dir/download.sh" "$script_url"
if [ ! -f "$temp_dir/download.sh" ]; then
    echo "Failed to download the script. Exiting."
    exit 1
fi
echo "Script downloaded successfully."

# Make the script executable
chmod +x "$temp_dir/download.sh"
if [ ! -x "$temp_dir/download.sh" ]; then
    echo "Failed to set execute permission on the script. Exiting."
    exit 1
fi
# Execute the script as the current user
echo "Executing the script as $current_user..."
su -l $current_user -c "bash $temp_dir/download.sh"

# Clean up: Optionally delete the temporary directory
# rm -r "$temp_dir"
