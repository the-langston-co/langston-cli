#!/bin/zsh

###############################################################
# Kandji audit script for the "Langston CLI" Custom Script library item.
#
# Paste into the item's Audit Script, with kandji.sh (repo root) as its
# Remediation Script and the execution frequency set to daily. Kandji runs the
# remediation only when this exits non-zero, then audits again.
#
#   exit 0 -> compliant, or nothing to do
#   exit 1 -> install/upgrade the CLI for the logged-in user
#
# Scope: upgrades existing installs, and installs for Fetch users (Fetch's
# start.sh calls `langston db start`). Macs with neither are left alone;
# engineers install from Self Service.
#
# After a release, raise MINIMUM_ENFORCED_VERSION to roll it out.
###############################################################
autoload is-at-least

MINIMUM_ENFORCED_VERSION="1.10.1"

current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')
if [[ -z $current_user ]]; then
  echo "No console user; nothing to do"
  exit 0
fi

version_file="/Users/$current_user/langston-cli/resources/VERSION.txt"
installed=$(/bin/cat "$version_file" 2>/dev/null | /usr/bin/tr -d ' \tv\n\r')

if [[ -z $installed ]]; then
  # Same lookup as kandji/fetch/minimum_enforced_version.zsh, which decides
  # whether Fetch counts as installed.
  fetch_path="$(/usr/bin/find /Applications /System/Applications /Library/ -maxdepth 3 -name "Fetch.app" 2>/dev/null | /usr/bin/head -1)"
  if [[ -n $fetch_path ]]; then
    echo "Fetch is installed ($fetch_path) but the langston CLI is missing for $current_user; installing"
    exit 1
  fi
  echo "langston CLI not installed for $current_user and Fetch absent; nothing to do"
  exit 0
fi

if is-at-least "$MINIMUM_ENFORCED_VERSION" "$installed"; then
  echo "langston CLI $installed >= $MINIMUM_ENFORCED_VERSION for $current_user"
  exit 0
fi

echo "langston CLI $installed < $MINIMUM_ENFORCED_VERSION for $current_user; upgrading"
exit 1
