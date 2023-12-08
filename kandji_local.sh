#!/bin/zsh

###############################################################
# Updated 2023-11-18 by Neil Poulin
# This script runs via Kandji to install the langston CLI
###############################################################
KANDJI_VERSION='v1.0.7'
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

echo "removing any existing file download" | tee -a "$log_file_path"
rm -f "$temp_dir/download.sh" | tee -a "$log_file_path"
echo "Using local script file"
cp ./bin/scripts/configure/download.sh "$temp_dir/download.sh" | tee -a "$log_file_path"

echo "✅  Copied file to output dir successfully" | tee -a "$log_file_path"

# Make sure the current user owns the directory and all files
chown -R "$current_user" "$temp_dir" | tee -a "$log_file_path"

# Make the script executable
chmod +x "$temp_dir/download.sh" | tee -a "$log_file_path"

if [ ! -x "$temp_dir/download.sh" ]; then
    echo "Failed to set execute permission on the script. Exiting." | tee -a "$log_file_path"
    exit 1
fi

# Execute the script as the current user
#echo "Executing the script as $current_user: ${temp_dir}/download.sh" | tee -a "$log_file_path"
#su -l "$current_user" -c "$temp_dir/download.sh" | tee -a "$log_file_path"
echo "Executing the script as ROOT ${temp_dir}/download.sh" | tee -a "$log_file_path"
"$temp_dir/download.sh" | tee -a "$log_file_path"
# Clean up: delete the temporary directory
#rm -r "$temp_dir"

echo | tee -a "$log_file_path"
echo "[Kandji] Installed langston-cli version $(langston -v)" | tee -a "$log_file_path"
echo | tee -a "$log_file_path"