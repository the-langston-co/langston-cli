#!/bin/zsh

###############################################################
# Updated 2023-11-18 by Neil Poulin
# This script runs via Kandji to install the langston CLI
###############################################################
KANDJI_VERSION='v1.0.3'
echo "*********************************************"
echo "* LANGSTON KANDJI INSTALL: $KANDJI_VERSION  *"
echo "*********************************************"
echo
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
echo "Downloading the install script from GitHub: ${script_url}"
curl -s -o "$temp_dir/download.sh" "$script_url"
if [ ! -f "$temp_dir/download.sh" ]; then
    echo "Failed to download the script. Exiting."
    exit 1
fi
echo "✅  Script downloaded successfully."

# Make sure the current user owns the directory and all files
chown -R "$current_user" "$temp_dir"

# Make the script executable
chmod +x "$temp_dir/download.sh"

if [ ! -x "$temp_dir/download.sh" ]; then
    echo "Failed to set execute permission on the script. Exiting."
    exit 1
fi

# Execute the script as the current user
echo "Executing the script as $current_user: ${temp_dir}/download.sh"
su -l "$current_user" -c "$temp_dir/download.sh"

# Clean up: delete the temporary directory
#rm -r "$temp_dir"

echo
echo "[Kandji] Installed langston-cli version $(langston -v)"
echo