#!/bin/zsh

###############################################################
# Updated 2023-11-18 by Neil Poulin
# This script runs via Kandji to install the langston CLI
###############################################################
KANDJI_VERSION='v2.0.0'
# Determine the current user
current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')

# Create a temporary directory in the user home directory
temp_dir="/Users/$current_user/langston-cli-tmp"
log_file_path="$temp_dir/log.txt"
mkdir -p "$temp_dir"
touch -a log_file_path

echo "" | tee -a "$log_file_path"
echo "" | tee -a "$log_file_path"
echo "" | tee -a "$log_file_path"
echo "" | tee -a "$log_file_path"

echo "*********************************************************************" | tee -a "$log_file_path"
echo "" | tee -a "$log_file_path"
echo "  [$(date +"%Y-%m-%d_%H-%M-%S")] LANGSTON KANDJI INSTALL: $KANDJI_VERSION  " | tee -a "$log_file_path"
echo "" | tee -a "$log_file_path"
echo "*********************************************************************" | tee -a "$log_file_path"
echo | tee -a "$log_file_path"

echo "whoami: $(whoami)" | tee -a "$log_file_path"
echo "current_user=$current_user" | tee -a "$log_file_path"
echo "Temporary directory created: $temp_dir" | tee -a "$log_file_path"
echo "Log file created at $log_file_path" | tee -a "$log_file_path"


# URL of the script to download
script_url="https://raw.githubusercontent.com/the-langston-co/langston-cli/main/bin/scripts/configure/download.sh"
echo "removing any existing file download" | tee -a "$log_file_path"
rm -f "$temp_dir/download.sh" | tee -a "$log_file_path"
# Download the script
echo "Downloading the install script from GitHub: ${script_url}" | tee -a "$log_file_path"
curl -s -o "$temp_dir/download.sh" -H 'Cache-Control: no-cache, no-store' "$script_url" | tee -a "$log_file_path"
if [ ! -f "$temp_dir/download.sh" ]; then
    echo "Failed to download the script. Exiting." | tee -a "$log_file_path"
    exit 1
fi
echo "✅  Script downloaded successfully." | tee -a "$log_file_path"

# Make sure the current user owns the directory and all files
chown -R "$current_user" "$temp_dir" | tee -a "$log_file_path"

# Make the script executable
chmod +x "$temp_dir/download.sh" | tee -a "$log_file_path"

if [ ! -x "$temp_dir/download.sh" ]; then
    echo "Failed to set execute permission on the script. Exiting." | tee -a "$log_file_path"
    exit 1
fi

# Execute the script as the current user
echo "Executing the script as $current_user: ${temp_dir}/download.sh" | tee -a "$log_file_path"
su -l "$current_user" -c "/bin/zsh $temp_dir/download.sh" | tee -a "$log_file_path"
#echo "Executing the script as ROOT ${temp_dir}/download.sh" | tee -a "$log_file_path"
#/bin/zsh "$temp_dir/download.sh" | tee -a "$log_file_path"


# Clean up: delete the temporary directory
#rm -r "$temp_dir"
CLI_DIR="/Users/$current_user/langston-cli"
VERSION_FILE="$CLI_DIR/resources/VERSION.txt"
echo | tee -a "$log_file_path"
# Read the user's install directly rather than running the CLI as root: CLI
# releases before this change resolve VERSION.txt against $HOME (/var/root).
# A failed read is logged, not turned into a non-zero exit: a failed Kandji
# remediation stops enforcement until the item is flushed, while exit 0 lets
# the next daily audit retry.
if INSTALLED_VERSION=$(cat "$VERSION_FILE"); then
  echo "[Kandji] Installed langston-cli version $INSTALLED_VERSION" | tee -a "$log_file_path"
else
  echo "[Kandji] ❌  Install did not complete: could not read $VERSION_FILE" | tee -a "$log_file_path"
fi
echo | tee -a "$log_file_path"